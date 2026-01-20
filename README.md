# 🎮 Gaming LiveOps Analysis — Retention, Monetization & A/B Testing

This repository contains a **LiveOps analytics project** built on top of the *Gamelytics Mobile Analytics Challenge* dataset from Kaggle:

🔗 https://www.kaggle.com/datasets/debs2x/gamelytics-mobile-analytics-challenge/data

The analysis reproduces the key workflows performed by LiveOps & Product Analytics teams in real mobile games, including:

- Cohort retention modeling  
- Monetization KPI analysis  
- A/B test evaluation  
- Linking retention depth to lifetime value (LTV)

An interactive dashboard built in **Tableau Public** summarizes the key insights:

📊 https://public.tableau.com/app/profile/federico.mistretta/viz/GamingLiveOpsAnalysisRetentionLTVABTesting/RetentionvsLifetimeValue

---

## 📌 Project Objectives

In a typical LiveOps context, product teams want to know:

1. How is player retention trending over time?
2. How effectively do different user cohorts monetize?
3. Does a test variant improve monetization?
4. What is the relationship between early engagement and lifetime value?

This project answers these questions using analytical pipelines and visual dashboards.

---

## 📦 Dataset Description

The project uses the **Gamelytics Mobile Analytics Challenge** dataset from Kaggle:

https://www.kaggle.com/datasets/debs2x/gamelytics-mobile-analytics-challenge/data

The main tables used for this analysis:

| Table | Description |
|-------|-------------|
| `reg_data.csv` | User registration and demographic information |
| `auth_data.csv` | Event-level logs with timestamps of user activity |
| `ab_test.csv` | Lifetime revenue per user |
| (Other CSVs are available in the dataset but not used for core LiveOps analysis) |

### ⚠️ Dataset Characteristics & Limitations

- Revenue is provided only as **lifetime revenue per user**
- No timestamped purchase events
- No gameplay progression (levels, sessions, missions)
- No device/country/channel attribution

Due to these constraints, **true temporal LTV curves (revenue by day since install) cannot be computed** without strong assumptions. Instead, we model LTV by segmenting users based on retention behavior.

---

## 🧠 Analytical Pipeline

### 1️⃣ Cohort and Retention Modeling

Users were grouped into daily cohorts by their install dates (`reg_date`).  
Events were mapped to a “days since install” field to construct cohort retention curves (D0–D30).

Core SQL views created:

- user_revenue
- cohort_ltv
- monetization_kpis

These show how monetization varies across cohorts and user segments.

---

### 3️⃣ A/B Test Evaluation

Users were grouped by their A/B test assignment (`testgroup`), and the effect of the test variant on monetization was analyzed.

Key metrics compared:

- ARPU
- Payer Rate
- ARPPU

Uplift calculations were generated using:
- ab_monetization_core
- ab_uplift


This simulates how a product experiment would be evaluated with monetization metrics in a mobile game.

---

### 4️⃣ Retention vs Lifetime Value (Refactored)

Because the dataset contains only **lifetime revenue**, daily LTV curves cannot be accurately computed.  
Instead, we segment users by **retention depth** — the maximum number of days a user was active from install.

Retention segments:

- D0 only
- D1–D3
- D4–D7
- D8–D14
- D15+

Using these segments, we compute:

- Average LTV per segment
- Payer rate per segment
- Number of users per segment

Core SQL views:

- user_retention_depth
- user_retention_bucket
- user_value_by_segment


This provides a robust and defendable way to link retention and lifetime value.

---

## 📊 Tableau Dashboards

The interactive dashboard on Tableau Public includes:

1. **User Retention Curve** – Daily retention trends by cohort
2. **Monetization KPIs** – ARPU / ARPPU / payer rate by cohort
3. **A/B Test Comparison** – Monetization comparison between test groups
4. **Retention vs Lifetime Value** – How retention depth affects LTV and payer probability

📊 **Dashboard Public Link:**  
https://public.tableau.com/app/profile/federico.mistretta/viz/GamingLiveOpsAnalysisRetentionLTVABTesting/RetentionvsLifetimeValue

---

## 📌 Key Insights

- **Early retention strongly correlates with monetization**: Users who retain through the first week tend to have higher lifetime revenue.
- **Payer rate increases with retention depth**: The probability a user pays at least once rises significantly for users who remain active longer.
- **Long-term users are fewer but more valuable**: A small fraction of the player base contributes disproportionately to revenue.
- **A/B variant impact**: The test variant shows measurable uplift in some monetization metrics (dataset dependent).

These insights align with practical LiveOps decision-making.

---

## 🛠 Tools & Skills Demonstrated

- **SQL (SQLite)**
  - Cohort modeling
  - KPI computation
  - Lifecycle segmentation

- **Python**
  - Data cleaning
  - Preprocessing for SQL

- **Tableau**
  - Business dashboard design
  - Data storytelling

---

## 👤 Author

**Federico Mistretta**  
Aspiring Junior Data Analyst / LiveOps Analyst (Gaming & Esports)

- GitHub: https://github.com/ZaylerX  
- Tableau Public: https://public.tableau.com/app/profile/federico.mistretta  
- LinkedIn: *https://www.linkedin.com/in/federico-mistretta/*

---

## 📌 How to Use

1. Download data from Kaggle  
2. Load the CSVs into SQLite  
3. Run the SQL pipeline to create views  
4. Connect Tableau to the database  
5. Explore the dashboards and edit visuals as needed
