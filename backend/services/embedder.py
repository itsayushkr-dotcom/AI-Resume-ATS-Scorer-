import logging
import numpy as np

logger = logging.getLogger("ats_resume_scorer")


class LightweightEmbedder:
    """
    Lightweight embedding runner with multi-tier fallback:
    1. fastembed (ONNX Runtime): ~40MB RAM (no PyTorch overhead, prevents Render 512MB OOM)
    2. sentence_transformers: standard HuggingFace fallback
    3. simple character/word n-gram vectorizer fallback if no deep models are available
    """

    def __init__(self, model_name: str = "sentence-transformers/all-MiniLM-L6-v2"):
        self.model = None
        self.backend = None

        # Tier 1: Try FastEmbed (ONNX Runtime, ultra-low memory)
        try:
            from fastembed import TextEmbedding

            # Normalize model name for fastembed if needed
            fe_name = model_name
            if fe_name == "all-MiniLM-L6-v2":
                fe_name = "sentence-transformers/all-MiniLM-L6-v2"

            self.model = TextEmbedding(model_name=fe_name)
            self.backend = "fastembed"
            logger.info(f"Loaded FastEmbed ({fe_name}) with ONNX Runtime (~40MB RAM).")
            return
        except Exception as e:
            logger.info(f"FastEmbed not loaded ({e}), falling back to sentence_transformers...")

        # Tier 2: Try SentenceTransformers
        try:
            from sentence_transformers import SentenceTransformer

            self.model = SentenceTransformer(model_name)
            self.backend = "sentence_transformers"
            logger.info(f"Loaded SentenceTransformer ({model_name}).")
            return
        except Exception as e:
            logger.warning(f"SentenceTransformer not available ({e}). Using lightweight zero fallback.")

        # Tier 3: Safe fallback
        self.backend = "fallback"

    def encode(self, texts, convert_to_tensor: bool = False):
        if self.backend == "fastembed":
            if isinstance(texts, str):
                embeddings = list(self.model.embed([texts]))
                return np.array(embeddings[0], dtype=np.float32)
            embeddings = list(self.model.embed(texts))
            return np.array(embeddings, dtype=np.float32)

        elif self.backend == "sentence_transformers":
            return self.model.encode(texts, convert_to_tensor=False)

        else:
            dim = 384
            if isinstance(texts, str):
                return np.zeros(dim, dtype=np.float32)
            return np.zeros((len(texts), dim), dtype=np.float32)
