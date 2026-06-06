import os
import json
import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

# Resolve absolute paths based on this file's location
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DOC_PATH = os.path.join(SCRIPT_DIR, "doc.txt")
INDEX_PATH = os.path.join(SCRIPT_DIR, "whatshoppy.index")
CHUNKS_PATH = os.path.join(SCRIPT_DIR, "chunks.json")

def parse_sections(filepath):
    """
    Reads doc.txt and splits it into sections by headings starting with #
    Returns a list of dicts: [{'title': str, 'content': str}]
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Source file not found at: {filepath}")
        
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    sections = []
    current_title = None
    current_content_lines = []
    
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('#'):
            # Save the previous section if it exists
            if current_title is not None:
                sections.append({
                    'title': current_title,
                    'content': '\n'.join(current_content_lines).strip()
                })
            current_title = stripped.lstrip('#').strip()
            current_content_lines = []
        else:
            if stripped == '---':
                continue
            if current_title is not None:
                current_content_lines.append(line)
                
    if current_title is not None:
        sections.append({
            'title': current_title,
            'content': '\n'.join(current_content_lines).strip()
        })
        
    return sections

def create_chunks(sections, chunk_size=160, overlap=30):
    """
    Creates chunks from sections.
    If a section is shorter than chunk_size words, keeps it as one chunk.
    If longer, splits it with overlap.
    """
    chunks = []
    
    for section in sections:
        title = section['title']
        content = section['content']
        words = content.split()
        num_words = len(words)
        
        if num_words <= chunk_size:
            chunks.append({
                'title': title,
                'content': content
            })
        else:
            start = 0
            while start < num_words:
                end = start + chunk_size
                chunk_words = words[start:end]
                chunk_text = ' '.join(chunk_words)
                
                chunks.append({
                    'title': title,
                    'content': chunk_text
                })
                
                if end >= num_words:
                    break
                start += (chunk_size - overlap)
                
    return chunks

def main():
    print("--- Starting Index Generation Pipeline ---")
    print(f"Reading document from: {DOC_PATH}")
    
    # 1. Parse sections
    sections = parse_sections(DOC_PATH)
    print(f"Parsed {len(sections)} sections from doc.txt")
    
    # 2. Create chunks
    chunks = create_chunks(sections, chunk_size=160, overlap=30)
    print(f"Generated {len(chunks)} chunks total")
    
    # 3. Prepare texts to embed
    # Format: "Section: {title}\nContent: {content}"
    embed_texts = []
    for chunk in chunks:
        embed_texts.append(f"Section: {chunk['title']}\nContent: {chunk['content']}")
        
    # 4. Generate embeddings
    print("Loading sentence-transformers/all-MiniLM-L6-v2 model...")
    model = SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')
    
    print("Generating embeddings...")
    embeddings = model.encode(embed_texts, show_progress_bar=True)
    embeddings = np.array(embeddings).astype('float32')
    
    # 5. Normalize embeddings for Cosine Similarity (IndexFlatIP)
    print("Normalizing embeddings...")
    faiss.normalize_L2(embeddings)
    
    # 6. Create FAISS Index
    dimension = embeddings.shape[1]
    print(f"Creating FAISS IndexFlatIP index with dimension: {dimension}")
    index = faiss.IndexFlatIP(dimension)
    index.add(embeddings)
    
    # 7. Save FAISS index
    print(f"Saving FAISS index to: {INDEX_PATH}")
    faiss.write_index(index, INDEX_PATH)
    
    # 8. Save chunks as json with embed_text
    print(f"Saving chunks metadata to: {CHUNKS_PATH}")
    chunks_with_embed = []
    for chunk, embed_text in zip(chunks, embed_texts):
        chunks_with_embed.append({
            'title': chunk['title'],
            'content': chunk['content'],
            'embed_text': embed_text
        })
        
    with open(CHUNKS_PATH, 'w', encoding='utf-8') as f:
        json.dump(chunks_with_embed, f, indent=2, ensure_ascii=False)
        
    print("--- Index Generation Completed Successfully! ---")

if __name__ == '__main__':
    main()
