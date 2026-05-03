from flask import Flask, request, jsonify
import joblib
import pandas as pd

app = Flask(__name__)
model = joblib.load('rent_model.pkl')

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    sample = pd.DataFrame([[
        data['months_paid_late'],
        data['months_skipped'],
        data['months_as_tenant'],
        data['rent_amount'],
        data['avg_days_late']
    ]], columns=['months_paid_late', 'months_skipped', 'months_as_tenant', 'rent_amount', 'avg_days_late'])
    
    prediction = model.predict(sample)[0]
    probability = model.predict_proba(sample)[0][1]
    
    return jsonify({
        'will_pay_late': int(prediction),
        'risk_percentage': round(float(probability) * 100, 1)
    })

if __name__ == '__main__':
    app.run(port=5001)