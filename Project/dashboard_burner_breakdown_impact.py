import streamlit as st
import pandas as pd
import altair as alt

# Define specific data values
data = pd.DataFrame({
    "Date": pd.date_range("2024-07-20", periods=100),
    "Utilization": [0.79,0.77,0.75,0.8,0.77,0.8,0.78,0.78,0.75,0.77,0.77,0.79,0.79,0.73,0.75,0.74,0.75,0.77,0.72,0.72,0.8,0.71,0.7,0.78,0.63,0.68,0.62,0.7,0.7,0.62,0.67,0.7,0.69,0.66,0.6,0.68,0.68,0.61,0.65,0.7,0.64,0.7,0.7,0.62,0.68,0.61,0.61,0.67,0.65,0.65,0.53,0.54,0.6,0.59,0.51,0.54,0.53,0.58,0.57,0.53,0.52,0.52,0.58,0.5,0.54,0.56,0.51,0.53,0.6,0.59,0.57,0.6,0.52,0.58,0.12,0.19,0.18,0.1,0.13,0.14,0.16,0.13,0.14,0.2,0.14,0.1,0.12,0.13,0.17,0.14,0.2,0.1,0.12,0.16,0.12,0.14,0.12,0.11,0.12,0.15]
})

# Define annotation points
annotations = pd.DataFrame({
    "Date": ["2024-08-12", "2024-09-08", "2024-10-02"],  # Dates to annotate
    "Utilization": [.68, .52, .14],  # Corresponding values
    "Text": ["1 Burner Broken", "2 Burners Broken", "3 Burners Broken"]  # Annotation text
     
})
annotations["Date"] = pd.to_datetime(annotations["Date"])

# Create a line chart with Altair
line_chart = alt.Chart(data).mark_line().encode(
    x="Date:T",
    y=alt.Y("Utilization:Q",axis=alt.Axis(format='%'))
)

# Create annotations as text marks

annotation_layer = alt.Chart(annotations).mark_text(
    align='left', color='red'
).encode(
    x="Date:T",
    y="Utilization:Q",
    text="Text"
    
)


# Combine the line chart and annotations

chart_with_annotations = (line_chart + annotation_layer).properties(
    title=alt.TitleParams(
        text="Kitchen Space Utilization",
        align="center",
        anchor="middle"  # Centering the title
    )
)

# Display in Streamlit

st.altair_chart(chart_with_annotations, use_container_width=True)
