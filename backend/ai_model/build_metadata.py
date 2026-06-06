#!/usr/bin/env python3
"""
Build category metadata lookup from the training CSV.
Groups (title, description) pairs by category for random sampling at inference time.
"""

import json
import os
import random
import pandas as pd

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, '..', '..'))

CSV_PATH = os.path.join(PROJECT_ROOT, 'dataset', 'train.csv')
OUTPUT_PATH = os.path.join(SCRIPT_DIR, 'category_metadata.json')
MAX_SAMPLES_PER_CATEGORY = 100


def main():
    print(f"[build_metadata] Loading CSV from {CSV_PATH}")
    df = pd.read_csv(CSV_PATH)

    if 'categories' not in df.columns or 'title' not in df.columns or 'description' not in df.columns:
        raise ValueError("CSV must contain 'categories', 'title', 'description' columns")

    # Clean whitespace
    df['categories'] = df['categories'].astype(str).str.strip()
    df['title'] = df['title'].astype(str).str.strip()
    df['description'] = df['description'].astype(str).str.strip()

    metadata = {}
    grouped = df.groupby('categories')

    for category, group in grouped:
        # Collect unique non-empty (title, description) pairs
        pairs = []
        seen = set()
        for _, row in group.iterrows():
            title = row['title']
            desc = row['description']
            if title and desc and len(title) > 2 and len(desc) > 5:
                key = (title, desc)
                if key not in seen:
                    seen.add(key)
                    pairs.append({"name": title, "description": desc})
            if len(pairs) >= MAX_SAMPLES_PER_CATEGORY:
                break

        if pairs:
            metadata[category] = pairs
            print(f"  {category}: {len(pairs)} samples")

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)

    print(f"[build_metadata] Saved metadata for {len(metadata)} categories to {OUTPUT_PATH}")


if __name__ == '__main__':
    main()
