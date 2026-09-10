# MINOR-PROJECT-03
Fraud detection engine built in pure SQL — 12 fraud patterns caught across 200K simulated fintech transactions. No ML, no Python.

# RedFlag — Fraud Detection Engine (Pure SQL)

A SQL-only fraud detection project simulating a fraud analyst role at a 
fictional Indian payment aggregator (PayFast). Analyzed 200,000 transactions 
across 6 months to catch 12 distinct fraud patterns — no machine learning, 
no Python, just SQL.

## Patterns Detected
- Velocity fraud (30+ txns/user/day)
- Round-amount clustering (money laundering signature)
- Card testing (30+ sub-₹10 txns/day)
- Failed-then-succeeded pairs
- Odd-hour concentration (bot activity, 2-5 AM window)
- Mule accounts (rapid credit-then-debit transfers)
- Refund abuse (>40% refund ratio)
- Merchant collusion (concentrated volume from few users)
- Structuring / just-under-KYC-threshold (₹9,999)
- Dormant-then-active (account takeover signature)
- Velocity spike (5x+ monthly transaction anomaly)
- Geographic impossibility (same user, two cities, <60 min)

## Tech Stack
MySQL — GROUP BY, HAVING, CASE WHEN, correlated subqueries, CTEs 
window functions (LAG, ROW_NUMBER).

## Files
- `RedFlag_PratheekshaNair.sql` — all 12 detection queries with comments
- `screenshots/` — sample query outputs

## Dataset
200,000 transactions, 6 months (Jan-Jun 2024), simulated Indian fintech 
data. Full dataset available on request (not included due to file size).
