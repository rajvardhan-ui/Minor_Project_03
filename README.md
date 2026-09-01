# Minor_Project_03
A production-ready fraud analytics engine built using pure MySQL to isolate and flag 12 distinct financial crime vectors across 200,000 transaction records.
# RedFlag: Payment Fraud Analytics Engine (Pure SQL)

A comprehensive fraud detection engine built entirely using optimized, pure SQL. This project simulates the work of a Risk Analyst processing **200,000 raw transactions** over a 6-month period for a high-volume fintech payment aggregator (**PayFast**). 

Instead of relying on heavy Machine Learning models, this framework leverages advanced database analytics to isolate and flag 12 distinct financial crime and system manipulation patterns.

---

## 🛠️ Core Analytical Techniques Used
*   **Advanced Analytical Window Functions:** Implemented `LAG()`, `ROW_NUMBER()`, and chronological `OVER (PARTITION BY... ORDER BY...)` layers to track immediate spatial and sequential anomalies.
*   **Multi-Tier Subqueries & Joins:** Utilized complex Self-Joins and Correlated `EXISTS` structures to catch rapid-velocity asset movements.
*   **Common Table Expressions (CTEs):** Broken down deep multi-layered transactional patterns into clean, performant, and sequential virtual query logic tables.
*   **Conditional Risk Aggregations:** Applied conditional statement matrixes (`CASE WHEN` structures embedded in mathematical operators) to track transactional behavior thresholds.

---

## 🕵️‍♂️ Investigated Fraud Patterns & Risk Vectors

### Tier 1: Baseline Behavioral Anomalies
*   **P1: Velocity Fraud:** Flagged users executing 30+ transactions within a single calendar date.
*   **P2: Round-Amount Clustering:** Caught automated account setups using consecutive fixed-tier transaction brackets (e.g., ₹10,000, ₹5,000).
*   **P3: Micro-Transaction Card Testing:** Isolated bots pinging micro-amounts (< ₹10) at high frequency to validate stolen card criteria.
*   **P4: High-Frequency Transaction Failures:** Identified credentials under brute-force attacks via rapid consecutive error states.
*   **P5: Odd-Hour Operational Concentration:** Flagged accounts processing over 80% of total activity during high-risk windows (2 AM – 4 AM).

### Tier 2: Structural & Integration Exploits
*   **P6: Mule Account Layering:** Tracked high-risk "Credit-in, Debit-out" loops where large sums vanish within 30 minutes.
*   **P7: Refund Reversal Abuse:** Flagged buyer accounts maintaining systemic refund ratios exceeding 40% of total volume.
*   **P8: Merchant Collusion Ring:** Identified rogue storefronts generating over 60% of total monthly processing volume from their top 5 users.
*   **P9: Structured Smurfing Limits:** Caught users deliberately routing continuous streams of exactly ₹9,999.00 payments to bypass mandatory limit flags.
*   **P10: Dormant Account Reactivation:** Flagged high-velocity usage bursts on accounts after a 90+ day period of inactivity.

### Tier 3: Complex Sequential & Geospatial Fraud
*   **P11: Velocity Volume Spikes:** Isolated users whose peak monthly transactional volume surged past 300% of their historical baseline average.
*   **P12: Geographic Impossibility (Location Spoofing):** Created an immediate alert system tracking consecutive transactions from different physical cities happening inside an impossible travel window ($\le 60$ minutes).

---

## 📂 Repository Contents
*   `Redflag_Rajvadhan.sql`: The complete production-ready script containing all 12 analytical execution models, formatted with standard uppercase keywords, optimized structural formatting, and data verification findings comments.

---

## 🚀 Impact & Takeaways
This project accurately mirrors production environment risk monitoring operations run daily at major financial platforms like **Razorpay, Cred, and PhonePe**. It showcases database performance optimization, threat landscape pattern identification, and the power of relational algebra in core risk infrastructure.
