export const aiLab = {
  title: 'AI Lab',
  subtitle: 'Exploring how AI models can run locally on constrained hardware such as Raspberry Pi.',
  experiments: [
    'Ollama',
    'Qwen Vision',
    'GLM-OCR',
    'SmolVLM',
    'OCR',
    'Computer Vision',
    'Local AI',
    'Edge AI',
  ],
  note: 'Experiments support the PFA-Dialyse vision pipeline. No benchmark claims unless measured on target hardware.',
  cloudVsEdge: {
    cloud: ['Remote APIs', 'Higher latency', 'Network dependency', 'Privacy considerations'],
    edge: ['On-device inference', 'Offline-capable paths', 'CPU/GPU constraints', 'Iterative model selection'],
  },
};
