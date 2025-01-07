import coremltools as ct
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
import numpy as np

def create_text_embeddings_model():
    """Create a simple text embeddings model using StandardScaler."""
    # Create and fit a simple scaler
    scaler = StandardScaler()
    # Create dummy data that represents word counts
    X = np.random.rand(100, 384)  # 384 dimensions as before
    scaler.fit(X)
    
    # Convert to CoreML
    model = ct.converters.sklearn.convert(
        scaler,
        "text",
        "embeddings"
    )
    model.save("TextEmbeddings.mlmodel")
    print("Created TextEmbeddings.mlmodel")

def create_message_classifier_model():
    """Create a simple message classifier using logistic regression."""
    # Create and fit a simple classifier with specific settings
    classifier = LogisticRegression(
        multi_class='ovr',  # One vs Rest
        solver='lbfgs',
        max_iter=1000
    )
    
    # Create dummy training data
    X = np.random.rand(100, 64)  # 64 features
    y = np.array([0, 1] * 50)  # Balanced binary labels
    
    # Train classifier
    classifier.fit(X, y)
    
    # Convert to CoreML with feature descriptions
    model = ct.converters.sklearn.convert(
        classifier,
        [("input", ct.models.datatypes.Array(64))],
        "requiresProcessing"
    )
    model.save("MessageClassifier.mlmodel")
    print("Created MessageClassifier.mlmodel")

if __name__ == '__main__':
    print("Generating CoreML models...")
    create_text_embeddings_model()
    create_message_classifier_model()
    print("Done!") 