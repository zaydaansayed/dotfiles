#!/usr/bin/env python3
import sys
import os
import json
import re
import traceback
import subprocess
import time
import ollama
from pypdf import PdfReader
from pathlib import Path

FIXED_SYSTEM_CONTEXT = """You are a direct, concise local desktop assistant and your name is Isaac.
- System environment: Linux, Hyprland (Wayland).
- Response style: Direct, accurate, technical when needed, no unnecessary fluff.
- Formatting: Always enclose code blocks in standard markdown triple backticks (```)."""

DYNAMIC_CONTEXT_FILE = os.path.join(Path.home(), "Documents", "ai_dynam_context.txt")

def search_internet(query):
    """Basic web search capability without needing API keys."""
    try:
        from duckduckgo_search import DDGS
        results = DDGS().text(query, max_results=3)
        if results:
            return "\n\n".join([f"Source: {r.get('title')}\nURL: {r.get('href')}\nContent: {r.get('body')}" for r in results])
        return "No relevant search results found."
    except ImportError:
        return "[Error: Internet search requires duckduckgo-search. Run: pip install duckduckgo-search]"
    except Exception as e:
        return f"[Search execution failed: {e}]"

def check_search_intent_fast(user_prompt):
    clean_prompt = user_prompt.strip().lower()
    if clean_prompt.startswith("/search"):
        return user_prompt.replace("/search", "", 1).strip()
    
    search_keywords = r"\b(weather|news|stock|price of|score|latest|current event|who is the current|today)\b"
    if re.search(search_keywords, clean_prompt):
        return user_prompt.strip()
        
    return None

def is_binary(file_path):
    try:
        with open(file_path, 'rb') as f:
            return b'\x00' in f.read(256)
    except Exception:
        return True

def parse_attachments(file_paths_arg, max_chars=2000):
    if not file_paths_arg or file_paths_arg == "[]":
        return [], ""

    try:
        parsed = json.loads(file_paths_arg)
        paths = parsed if isinstance(parsed, list) else [str(parsed)]
    except Exception:
        paths = [file_paths_arg]

    images, text_contexts = [], []

    for path in paths:
        path = str(path).strip()
        if not path or not os.path.exists(path):
            continue

        ext = os.path.splitext(path)[1].lower()

        if ext in ['.jpg', '.jpeg', '.png', '.webp', '.bmp']:
            images.append(path)
            continue
        if is_binary(path):
            text_contexts.append(f"FILE ({os.path.basename(path)}): [Binary file ignored]")
            continue
        if ext == '.pdf':
            try:
                reader = PdfReader(path)
                text = "\n".join([page.extract_text() for page in reader.pages[:5] if page.extract_text()])
                text_contexts.append(f"FILE ({os.path.basename(path)}):\n{text[:max_chars]}")
            except Exception as e:
                text_contexts.append(f"Error reading PDF {os.path.basename(path)}: {e}")
            continue

        try:
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read(max_chars)
                if len(content) >= max_chars:
                    content += "\n... [Content Truncated]"
                text_contexts.append(f"FILE ({os.path.basename(path)}):\n{content}")
        except Exception as e:
            text_contexts.append(f"Error reading {os.path.basename(path)}: {e}")

    return images, "\n\n".join(text_contexts)

def parse_response_blocks(text):
    pattern = r"```(?:\w+)?\n?(.*?)```"
    blocks = []
    last_end = 0

    for match in re.finditer(pattern, text, re.DOTALL):
        pre_text = text[last_end:match.start()].strip()
        if pre_text:
            blocks.append({"type": "text", "content": pre_text})

        code_content = match.group(1).strip()
        if code_content:
            blocks.append({"type": "code", "content": code_content})
        last_end = match.end()

    post_text = text[last_end:].strip()
    if post_text:
        blocks.append({"type": "text", "content": post_text})
    if not blocks:
        blocks.append({"type": "text", "content": text})

    return blocks

def describe_image_with_moondream(image_path):
    try:
        res = ollama.chat(
            model="moondream",
            messages=[{
                "role": "user",
                "content": "Describe this image briefly.",
                "images": [image_path]
            }]
        )
        return res.get('message', {}).get('content', '').strip()
    except Exception as e:
        return f"[Image description failed: {e}]"

def read_dynamic_context():
    if os.path.exists(DYNAMIC_CONTEXT_FILE):
        try:
            with open(DYNAMIC_CONTEXT_FILE, 'r', encoding='utf-8') as f:
                return f.read().strip()
        except Exception:
            return ""
    return ""

def update_eww_live(raw_history_list, current_prompt, streaming_text, parsed_attachments):
    """Pushes in-flight tokens directly into eww state for real-time UI streaming."""
    try:
        active_blocks = parse_response_blocks(streaming_text)
        current_turn = {
            "prompt": current_prompt,
            "response": active_blocks,
            "attachments": parsed_attachments
        }
        updated_history = raw_history_list + [current_turn]
        subprocess.run(["eww", "update", f"ai_txt={json.dumps(updated_history)}"], check=False)
    except Exception:
        pass

def process_ai_request(user_prompt, file_paths_arg, history_json_str):
    try:
        search_context = ""
        search_query = check_search_intent_fast(user_prompt)

        if search_query:
            search_context = f"INTERNET SEARCH RESULTS FOR '{search_query}':\n{search_internet(search_query)}\n\n"

        history_messages = []
        raw_history = []
        try:
            raw_history = json.loads(history_json_str) if history_json_str else []
            for item in raw_history:
                p = item.get("prompt", "").strip()
                r_obj = item.get("response", [])
                
                res_text = ""
                if isinstance(r_obj, list):
                    res_text = "\n\n".join([f"```\n{b['content']}\n```" if b.get('type') == 'code' else b.get('content', '') for b in r_obj])
                elif isinstance(r_obj, str):
                    res_text = r_obj

                if p: history_messages.append({"role": "user", "content": p})
                if res_text: history_messages.append({"role": "assistant", "content": res_text})
        except Exception:
            pass

        system_parts = [FIXED_SYSTEM_CONTEXT]
        dynamic_context = read_dynamic_context()
        if dynamic_context:
            system_parts.append(f"SYSTEM DYNAMIC CONTEXT:\n{dynamic_context}")
        system_instruction = "\n\n".join(system_parts)

        images, file_context = parse_attachments(file_paths_arg)
        context_blocks = []
        
        if search_context:
            context_blocks.append(search_context)
            
        if images:
            context_blocks.append("\n\n".join([f"IMAGE ({os.path.basename(p)}):\n{describe_image_with_moondream(p)}" for p in images]))
            
        if file_context:
            context_blocks.append(file_context)

        combined_prompt = f"ATTACHED CONTEXT:\n{chr(10).join(context_blocks)}\n\nUSER PROMPT: {user_prompt}" if context_blocks else user_prompt

        messages = [{"role": "system", "content": system_instruction}]
        messages.extend(history_messages)
        messages.append({"role": "user", "content": combined_prompt})

        # Parse raw attachments array for the live UI update
        try:
            parsed_attachments = json.loads(file_paths_arg) if file_paths_arg else []
        except Exception:
            parsed_attachments = []

        # STREAMING API CALL
        stream = ollama.chat(
            model="qwen2.5:3b",
            messages=messages,
            options={
                "num_ctx": 1024,
                "num_thread": 4
            },
            stream=True
        )

        full_content = ""
        last_update_time = time.time()

        for chunk in stream:
            token = chunk.get('message', {}).get('content', '')
            full_content += token

            # Throttle UI updates slightly (every 50ms) to reduce widget render lag
            if time.time() - last_update_time > 0.05:
                update_eww_live(raw_history, user_prompt, full_content, parsed_attachments)
                last_update_time = time.time()

        # Push final update to capture completed response
        update_eww_live(raw_history, user_prompt, full_content, parsed_attachments)

        content = full_content.strip()
        if not content:
            return json.dumps([{"type": "text", "content": "[Error: Model returned an empty response.]"}])
            
        return json.dumps(parse_response_blocks(content))

    except Exception as e:
        return json.dumps([{"type": "text", "content": f"[Python Execution Error]: {str(e)}\n{traceback.format_exc()}"}])

if __name__ == "__main__":
    if len(sys.argv) > 1:
        prompt_arg = sys.argv[1]
        file_arg = sys.argv[2] if len(sys.argv) > 2 else "[]"
        history_arg = sys.argv[3] if len(sys.argv) > 3 else "[]"

        output = process_ai_request(prompt_arg, file_arg, history_arg)
        print(output)
    else:
        print("Usage: python ai.py <prompt> [json_file_paths] [history_json]")
