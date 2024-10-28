import faker
import streamlit as st
import datetime
import pandas as pd
import numpy as np
import time
import altair as alt

fake = faker.Faker()
current_day = datetime.datetime.now().strftime('%A')
st.session_state.current_day = current_day
current_hour = datetime.datetime.now().hour
st.session_state.current_hour = current_hour


# Generate historical data - use session state to persist data
if 'historical_df' not in st.session_state:
    data = []
    for _ in range(1000):
        day = fake.day_of_week()
        hour = fake.random_int(min=0, max=23)  # Operating hours midnight-11pm
        usage_count = fake.random_int(min=10, max=100)
        visit_duration = fake.random_int(min=15, max=120)  # Duration in minutes
        data.append([day, hour, usage_count, visit_duration])
    st.session_state.historical_df = pd.DataFrame(data, columns=['day', 'hour', 'usage_count', 'visit_duration'])

# Generate live data
def generate_live_data():
    current_hour = datetime.datetime.now().hour
    current_day = datetime.datetime.now().strftime('%A')
    current_usage = fake.random_int(min=10, max=100)
    return current_day, current_hour, current_usage

# Streamlit app
st.title("Restaurant Usage Patterns")

# Day selection
days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
selected_day = st.radio("Select Day:", days, horizontal=True)

# Filter data for selected day
day_data = st.session_state.historical_df[st.session_state.historical_df['day'] == selected_day]
avg_by_hour = day_data.groupby('hour')['usage_count'].mean().reset_index()

# Create data for chart
chart_data = pd.DataFrame({
    'Hour': range(0, 24),
    'Historical Usage': [avg_by_hour[avg_by_hour['hour'] == hour]['usage_count'].iloc[0] if not avg_by_hour[avg_by_hour['hour'] == hour].empty else 0 for hour in range(0, 24)]
})

# Auto-refresh live data every minute
@st.fragment(run_every=5)
def refresh_live_data():

    #st.session_state.last_refresh = time.time()
    st.session_state.current_day, st.session_state.current_hour, st.session_state.current_usage = generate_live_data()
    status=""
    refresh_data=chart_data
    # Add live data if current day matches selected day
    if st.session_state.current_day == selected_day:
        
        refresh_data.loc[refresh_data['Hour'] == st.session_state.current_hour, 'Live Usage'] = st.session_state.current_usage
        historical_avg = avg_by_hour[avg_by_hour['hour'] == st.session_state.current_hour]['usage_count'].iloc[0]
        status = "busier than usual" if st.session_state.current_usage > historical_avg else "less busy than usual"
    # Melt the dataframe for Altair
    melted_data = pd.melt(refresh_data, id_vars=['Hour'], var_name='Type', value_name='Usage')
    
    # Create overlapping bar chart with Altair - with improved styling
    historical_bars = alt.Chart(melted_data[melted_data['Type'] == 'Historical Usage']).mark_bar(
        opacity=0.8,
        color='#4B89DC',  # Softer blue
        size=25
    ).encode(
    x=alt.X('Hour:Q', scale=alt.Scale(domain=[0, 24])),  # Fixed x-axis range
    y=alt.Y('Usage:Q', title='Number of People'),
        tooltip=['Hour:Q', 'Usage:Q']
    )

    live_bars = alt.Chart(melted_data[melted_data['Type'] == 'Live Usage']).mark_bar(
        opacity=0.6,
        color='#E74C3C',  # Softer red
        size=28,
        tooltip=True  # Always show tooltip
    ).encode(
        x=alt.X('Hour:Q', scale=alt.Scale(domain=[0, 24])),  # Fixed x-axis range
        y=alt.Y('Usage:Q', title='Number of People'),
        tooltip=['Hour:Q', 'Usage:Q']
    )

    chart = (historical_bars + live_bars).properties(
        width=800,
    height=400,
    title=f"Hourly Usage Pattern({status})"
    ).configure_axis(
        grid=False,
        gridColor='#EEEEEE'  # Light gray grid
    ).configure_view(
        strokeWidth=0  # Remove border
    )

    st.altair_chart(chart)
    

st.session_state.current_day, st.session_state.current_hour, st.session_state.current_usage = generate_live_data()
refresh_live_data()
# Add busy status


# Summary statistics
avg_duration = st.session_state.historical_df['visit_duration'].mean()
st.metric("Average Visit Duration", f"{avg_duration:.0f} minutes")