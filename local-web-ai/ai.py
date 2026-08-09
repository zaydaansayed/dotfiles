import sys
import os
import json
import re
import traceback
import ollama
from pypdf import PdfReader

STORAGE_FILE = "/home/zaydaansayed/Documents/ai.txt"

FIXED_SYSTEM_CONTEXT = """You are a direct, concise local desktop assistant.
- System environment: Arch Linux, Hyprland (Wayland), Kitty, Neovim.
- Response style: Direct, accurate, technical when needed, no unnecessary fluff.
- Formatting: Always enclose code blocks in standard markdown triple backticks (```)."""

def ensure_storage():
    os.makedirs(os.path.dirname(STORAGE_FILE), exist_ok=True)
    if not os.path.exists(STORAGE_FILE):
        with open(STORAGE_FILE, 'w', encoding='utf-8') as f:
            json.dump({}, f)

def load_chats():
    ensure_storage()
    try:
        with open(STORAGE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {}

def save_chats(data):
    ensure_storage()
    with open(STORAGE_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)

def is_binary(file_path):
    try:
        with open(file_path, 'rb') as f:
            return b'\x00' in f.read(1024)
    except Exception:
        return True

def parse_attachments(file_paths_arg, max_chars=2000):
    if not file_paths_arg or file_paths_arg == "[]":
        return [], ""

    paths = []
    try:
        parsed = json.loads(file_paths_arg)
        paths = parsed if isinstance(parsed, list) else [str(parsed)]
    except Exception:
        paths = [file_paths_arg]

    images = []
    text_contexts = []

    for path in paths:
        path = str(path).strip()
        if not path or not os.path.exists(path):
            text_contexts.append(f"FILE ({os.path.basename(path)}): [File not found]")
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
                text = "\n".join([page.extract_text() for page in reader.pages if page.extract_text()])
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
                "content": "Describe this image in clear, concise detail, noting key visual elements, text, and objects.",
                "images": [image_path]
            }]
        )
        return res.get('message', {}).get('content', '').strip()
    except Exception as e:
        return f"[Image description failed: {e}]"

def ask_local_ai_headless(user_prompt, file_paths_arg=None, dynamic_context=None, chat_id="current"):
    try:
        chat_id = re.sub(r'[^a-zA-Z0-9_\-]', '_', chat_id or "current")
        chats = load_chats()

        if chat_id not in chats:
            chats[chat_id] = {"title": "New Chat", "history": []}
        elif isinstance(chats[chat_id], list):
            chats[chat_id] = {"title": "New Chat", "history": chats[chat_id]}

        chat_data = chats[chat_id]

        # Auto-generate title if it's new or empty
        if chat_data.get("title") in ["New Chat", ""] or not chat_data.get("title"):
            try:
                res_title = ollama.chat(
                    model="qwen2.5:1.5b",
                    messages=[{
                        "role": "user",
                        "content": f"Summarize this prompt in 3 to 5 words as a short title. Return ONLY the title with no quotes, formatting, or period: {user_prompt}"
                    }]
                )
                title = res_title.get('message', {}).get('content', '').strip().replace('"', '').replace("'", "")
                if title:
                    chat_data["title"] = title
            except Exception:
                pass

        raw_history = chat_data.get("history", [])

        # Reconstruct chat thread messages
        history_messages = []
        for item in raw_history:
            prompt = item.get("prompt", "").strip()
            response_obj = item.get("response", [])

            res_text = ""
            if isinstance(response_obj, list):
                parts = []
                for block in response_obj:
                    if isinstance(block, dict):
                        btype = block.get("type", "text")
                        content = block.get("content", "")
                        if btype == "code":
                            parts.append(f"```\n{content}\n```")
                        else:
                            parts.append(content)
                    res_text = "\n\n".join(parts)
            elif isinstance(response_obj, str):
                res_text = response_obj

            if prompt:
                history_messages.append({"role": "user", "content": prompt})
            if res_text:
                history_messages.append({"role": "assistant", "content": res_text})

        # System Context Configuration
        system_parts = [FIXED_SYSTEM_CONTEXT]
        if dynamic_context and dynamic_context.strip():
            system_parts.append(f"SYSTEM DYNAMIC CONTEXT:\n{dynamic_context.strip()}")

        system_instruction = "\n\n".join(system_parts)

        # File & Image Attachments Processing
        images, file_context = parse_attachments(file_paths_arg)

        image_descriptions = []
        if images:
            for img_path in images:
                desc = describe_image_with_moondream(img_path)
                image_descriptions.append(f"IMAGE ({os.path.basename(img_path)}):\n{desc}")

        context_blocks = []
        if image_descriptions:
            context_blocks.append("\n\n".join(image_descriptions))
        if file_context:
            context_blocks.append(file_context)

        if context_blocks:
            full_context = "\n\n".join(context_blocks)
            combined_prompt = f"ATTACHED FILE CONTEXT:\n{full_context}\n\nUSER PROMPT: {user_prompt}"
        else:
            combined_prompt = user_prompt

        messages = [{"role": "system", "content": system_instruction}]
        messages.extend(history_messages)
        messages.append({"role": "user", "content": combined_prompt})

        # Model Query
        res = ollama.chat(
            model="qwen2.5:1.5b",
            messages=messages,
            options={"num_ctx": 4096}
        )

        content = res.get('message', {}).get('content', '').strip()
        if not content:
            parsed_blocks = [{"type": "text", "content": "[Error: qwen2.5:1.5b returned an empty response.]"}]
        else:
            parsed_blocks = parse_response_blocks(content)

        # Save State
        attachments_list = []
        if file_paths_arg and file_paths_arg != "[]":
            try:
                attachments_list = json.loads(file_paths_arg)
            except Exception:
                attachments_list = [file_paths_arg]

        chat_data["history"].append({
            "prompt": user_prompt,
            "response": parsed_blocks,
            "attachments": attachments_list
        })

        chats[chat_id] = chat_data
        save_chats(chats)

        return json.dumps(parsed_blocks)

    except Exception as e:
        err_msg = f"[Python Execution Error]: {str(e)}\n{traceback.format_exc()}"
        return json.dumps([{"type": "text", "content": err_msg}])

if __name__ == "__main__":
    if len(sys.argv) > 1:
        prompt_arg = sys.argv[1]
        file_arg = sys.argv[2] if len(sys.argv) > 2 else None
        dynamic_arg = sys.argv[3] if len(sys.argv) > 3 else None
        chat_id_arg = sys.argv[4] if len(sys.argv) > 4 else "current"

        output = ask_local_ai_headless(prompt_arg, file_arg, dynamic_arg, chat_id_arg)
        print(output)
    else:
        print("Usage: python ai.py <prompt> [json_file_paths] [dynamic_context] [chat_id]")
