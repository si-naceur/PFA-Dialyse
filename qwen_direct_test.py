import torch
from transformers import Qwen2_5_VLForConditionalGeneration, AutoProcessor

MODEL = "Qwen/Qwen2.5-VL-3B-Instruct"
IMAGE = "ecran_machine.jpeg"

print("Loading Qwen on GPU...")

model = Qwen2_5_VLForConditionalGeneration.from_pretrained(
    MODEL,
    torch_dtype=torch.float16,
    device_map="auto",
    low_cpu_mem_usage=True,
)

processor = AutoProcessor.from_pretrained(
    MODEL,
    min_pixels=256 * 256,
    max_pixels=1024 * 1024,
)

conversation = [
    {
        "role": "user",
        "content": [
            {
                "type": "image",
                "image": IMAGE,
            },
            {
                "type": "text",
                "text": """
Analyze the entire dialysis machine screen carefully.

IMPORTANT:
The blood flow value Qb is displayed as a numeric value on the screen.
Do not return null for Qb unless you have genuinely inspected the whole image.

Identify the labels and their corresponding displayed numbers.
Pay special attention to the Qb / blood flow field.

Extract:
qb, pv, pa, ptm, uf_volume, uf_rate, heparin.

Return ONLY valid JSON:

{
  "qb": number or null,
  "pv": number or null,
  "pa": number or null,
  "ptm": number or null,
  "uf_volume": number or null,
  "uf_rate": number or null,
  "heparin": number or null
}

Preserve negative signs exactly.
Do not infer or calculate values.
Do not confuse Qb with another numerical value.
"""
            },
        ],
    }
]

print("Preparing image...")

inputs = processor.apply_chat_template(
    conversation,
    add_generation_prompt=True,
    tokenize=True,
    return_dict=True,
    return_tensors="pt",
)

# Move tensors to the model's device
inputs = inputs.to(model.device)

print("Running Qwen inference on GPU...")

with torch.inference_mode():
    generated_ids = model.generate(
        **inputs,
        max_new_tokens=150,
        do_sample=False,
    )

generated_ids = [
    output_ids[len(input_ids):]
    for input_ids, output_ids in zip(
        inputs.input_ids,
        generated_ids
    )
]

output = processor.batch_decode(
    generated_ids,
    skip_special_tokens=True,
    clean_up_tokenization_spaces=False,
)

print("\n========== QWEN GPU ==========")
print(output[0])

print("\n========== GPU STATUS ==========")
print("GPU:", torch.cuda.get_device_name(0))
print(
    "VRAM used:",
    round(torch.cuda.memory_allocated(0) / 1024**3, 2),
    "GB"
)