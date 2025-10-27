import os
import pandas as pd
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.metrics import accuracy_score

def main():

    # Load datasets
    train = pd.read_csv("src/data/train.csv")
    test  = pd.read_csv("src/data/test.csv")
    sub   = pd.read_csv("src/data/gender_submission.csv")
    print(f"[INFO] train shape: {train.shape}, test shape: {test.shape}, submission shape: {sub.shape}")

    # Feature engineering
    train["FamilySize"] = train["SibSp"] + train["Parch"] + 1
    test["FamilySize"]  = test["SibSp"] + test["Parch"] + 1
    print("[FE] Created feature FamilySize")

    train["IsMale"] = (train["Sex"] == "male").astype(int)
    test["IsMale"]  = (test["Sex"] == "male").astype(int)
    print("[FE] Created feature IsMale")

    # Prepare data for modeling
    y_train  = train["Survived"]
    features = ["Pclass", "Fare", "Age", "FamilySize", "IsMale"]
    print(f"[FEATURES] Using features: {features}")

    X_train = train[features].copy()
    X_test  = test[features].copy()

    numeric_features     = ["Fare", "Age", "FamilySize"]
    categorical_features = ["Pclass", "IsMale"]

    numeric_transformer = Pipeline([
        ("imputer", SimpleImputer(strategy="median")),
        ("scaler",  StandardScaler())
    ])
    categorical_transformer = Pipeline([
        ("imputer", SimpleImputer(strategy="most_frequent")),
        ("onehot",   OneHotEncoder(handle_unknown="ignore", sparse_output=False))
    ])

    preprocessor = ColumnTransformer([
        ("num", numeric_transformer,     numeric_features),
        ("cat", categorical_transformer, categorical_features)
    ], remainder="drop")

    model = Pipeline([
        ("preprocessor", preprocessor),
        ("classifier",   LogisticRegression(max_iter=500))
    ])

    print("[TRAIN] Fitting logistic regression model...")
    model.fit(X_train, y_train)

    # Training accuracy
    train_preds = model.predict(X_train)
    train_acc   = accuracy_score(y_train, train_preds)
    print(f"[METRIC] TRAIN accuracy: {train_acc:.4f}")

    # Test predictions
    print("[PREDICT] Predicting on test set...")
    test_preds = model.predict(X_test)
    print("[OUTPUT] First 20 predictions:", test_preds[:20].tolist())

    # Merge predictions with true labels from submission file
    merged = test[["PassengerId"]].copy()
    merged["Predicted"] = test_preds
    merged = merged.merge(sub, on="PassengerId", how="left", suffixes=("", "_true"))
    merged = merged.dropna(subset=["Survived"])
    test_acc = accuracy_score(merged["Survived"], merged["Predicted"])
    print(f"[METRIC] TEST accuracy (using gender_submission as true labels): {test_acc:.4f}")

if __name__ == "__main__":
    main()