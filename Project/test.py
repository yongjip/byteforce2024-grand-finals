import faker
import streamlit as st

import datetime
import pandas as pd
import numpy as np

fake = faker.Faker()

# Generate historical data
def generate_historical_data():
    data = []
    for _ in range(1000):
        day = fake.day_of_week()
        hour = fake.random_int(min=6, max=23)  # Operating hours 6am-11pm
        usage_count = fake.random_int(min=10, max=100)
        visit_duration = fake.random_int(min=15, max=120)  # Duration in minutes
        data.append([day, hour, usage_count, visit_duration])
    return pd.DataFrame(data, columns=['day', 'hour', 'usage_count', 'visit_duration'])

# Generate live data
def generate_live_data():
    current_hour = datetime.datetime.now().hour
    current_day = datetime.datetime.now().strftime('%A')
    current_usage = fake.random_int(min=10, max=100)
    return current_day, current_hour, current_usage

# Load data
historical_df = generate_historical_data()

# Streamlit app
st.title("Restaurant Usage Patterns")

# Day selection
days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
selected_day = st.radio("Select Day:", days, horizontal=True)

# Get current data
current_day, current_hour, current_usage = generate_live_data()

# Filter data for selected day
day_data = historical_df[historical_df['day'] == selected_day]
avg_by_hour = day_data.groupby('hour')['usage_count'].mean().reset_index()

# Create bar chart
chart_data = pd.DataFrame({
    'Hour': range(6, 24),
    'Historical Usage': [avg_by_hour[avg_by_hour['hour'] == hour]['usage_count'].iloc[0] if not avg_by_hour[avg_by_hour['hour'] == hour].empty else 0 for hour in range(6, 24)]
})

# Add live data if current day matches selected day
if current_day == selected_day:
    chart_data.loc[chart_data['Hour'] == current_hour, 'Live Usage'] = current_usage

# Plot chart
st.bar_chart(chart_data.set_index('Hour'))

# Add busy status
if current_day == selected_day:
    historical_avg = avg_by_hour[avg_by_hour['hour'] == current_hour]['usage_count'].iloc[0]
    status = "busier than usual" if current_usage > historical_avg else "less busy than usual"
    st.info(f"Current Status: {status}")

# Summary statistics
avg_duration = historical_df['visit_duration'].mean()
st.metric("Average Visit Duration", f"{avg_duration:.0f} minutes")
