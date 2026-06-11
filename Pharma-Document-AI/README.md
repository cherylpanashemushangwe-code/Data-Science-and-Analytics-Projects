# Pharmaceutical Document AI: OCR and RAG

An independent learning project exploring document AI for pharmaceutical-style documents. It combines optical character recognition for scanned PDFs with a Retrieval-Augmented Generation (RAG) pipeline that answers natural language questions and cites its sources.

> This is a personal project built on synthetic and publicly available sample documents. It contains no proprietary or confidential data.

## What is inside
| File | Description |
| --- | --- |
| `pharmaceutical_ocr_extraction.ipynb` | OCR pipeline (Tesseract) that extracts text from scanned or image-only PDF pages, with fallback handling for mixed document formats |
| `rag_pipeline_llamaindex_gemini.ipynb` | RAG pipeline (LlamaIndex with a Gemini model) using chunking and vector retrieval to return source-cited answers |

## Approach
- OCR extraction with Tesseract, including an image-only page fallback
- Sentence-boundary chunking and vector retrieval for relevant context
- RAG question answering that returns answers with source references

## Setup
1. Install requirements such as `llama-index`, `pytesseract`, `pdf2image`, and the Google Generative AI client. Tesseract must be installed on your system.
2. Set your model credentials as an environment variable, for example `GOOGLE_API_KEY`. Do not hardcode keys in the notebook.
3. Open the notebooks in Jupyter or Google Colab and run the cells in order.

## Security
API keys are read from environment variables or Colab secrets. No keys are stored in this repository.

## Tech
Python, LlamaIndex, Tesseract OCR, vector retrieval, Gemini.
