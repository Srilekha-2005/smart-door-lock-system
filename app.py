from flask import Flask, jsonify, request
import pandas as pd
from sklearn.tree import DecisionTreeClassifier

app = Flask(__name__)

# 1) Load dataset from CSV
data = pd.read_csv("login_data.csv")

# 2) Split into features (X) and target (y)
X_train = data[["attempts", "time_gap"]]
y_train = data["label"]

# 3) Train model when app starts
model = DecisionTreeClassifier(random_state=42)
model.fit(X_train, y_train)


@app.route("/analyze", methods=["POST"])
def analyze():
    data = request.get_json(silent=True)

    if data is None:
        return jsonify({"message": "Please send valid JSON data.", "status": "normal"}), 400

    attempts = data.get("attempts")
    time_gap = data.get("time_gap")

    if not isinstance(attempts, int) or not isinstance(time_gap, int):
        return (
            jsonify(
                {
                    "status": "normal",
                    "message": "Both 'attempts' and 'time_gap' must be integers.",
                }
            ),
            400,
        )

    # 4) Predict using model
    prediction = model.predict([[attempts, time_gap]])[0]

    if prediction == 1:
        return jsonify(
            {
                "status": "intrusion",
                "message": "Model detected suspicious lock activity.",
            }
        )

    return jsonify(
        {
            "status": "normal",
            "message": "Activity looks normal.",
        }
    )


if __name__ == "__main__":
    app.run(debug=True)
