# File: backend/app/nltk_download.py

import nltk

def download_nltk_resources():
    """Download required NLTK resources."""
    
    # List of resources we need
    resources = [
        'punkt',                              # Sentence and word tokenizer
        'stopwords',                          # Common words list
        'wordnet',                            # Word meanings dictionary
        'averaged_perceptron_tagger_eng'      # Part of speech tagger
    ]
    
    # Download each resource
    for resource in resources:
        try:
            nltk.download(resource, quiet=True)
            print(f"Downloaded NLTK resource: {resource}")
        except Exception as e:
            print(f"Error downloading {resource}: {str(e)}")

# Run the function if this file is executed directly
if __name__ == "__main__":
    download_nltk_resources()