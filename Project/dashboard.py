import streamlit as st
import datetime
import pandas as pd
import numpy as np
import altair as alt
import random
from faker import Faker

# Constants
REVENUE_PER_RESIDENT = 100
REVENUE_PER_HOUR_AMENITY_USAGE = REVENUE_PER_RESIDENT / 24

# Hourly usage percentages
hour_usage_pct = {
    0: 0.1, 1: 0.1, 2: 0.05, 3: 0.03, 4: 0.02, 5: 0.01, 6: 0.02,
    7: 0.03, 8: 0.03, 9: 0.05, 10: 0.1, 11: 0.1, 12: 0.2,
    13: 0.2, 14: 0.2, 15: 0.2, 16: 0.2, 17: 0.2, 18: 0.2,
    19: 0.2, 20: 0.1, 21: 0.1, 22: 0.1, 23: 0.1
}

# Hotel amenities
hotel_amenities = {
    'Lyf Funan': [
        'Connect - Social Co-Working Space',
        'Open Connect - Social & Sip',
        'Bond - Social Kitchen',
        'Burn - Social Gym',
        'Wash & Hang - Laundromat',
        'Meet - Social Meeting Space',
        'Colab - Social Co-Working Space',
    ],
    'Lyf Farrer': [
        'Connect - Social Co-Working Space',
        'Open Connect - Social & Sip',
        'Bond - Social Kitchen',
        'Burn - Social Gym',
        'Wash & Hang - Laundromat',
        'Meet - Social Meeting Space',
        'Colab - Social Co-Working Space',
    ],
}

# Amenity sizes
funan_amenity_size = {
    'Connect - Social Co-Working Space': 100,
    'Open Connect - Social & Sip': 20,
    'Bond - Social Kitchen': 50,
    'Burn - Social Gym': 30,
    'Wash & Hang - Laundromat': 30,
    'Meet - Social Meeting Space': 30,
    'Colab - Social Co-Working Space': 30,
}

farrer_amenity_size = {
    'Connect - Social Co-Working Space': 80,
    'Open Connect - Social & Sip': 30,
    'Bond - Social Kitchen': 40,
    'Burn - Social Gym': 40,
    'Wash & Hang - Laundromat': 30,
    'Meet - Social Meeting Space': 30,
    'Colab - Social Co-Working Space': 30,
}

amenity_size = {
    'Lyf Funan': funan_amenity_size,
    'Lyf Farrer': farrer_amenity_size
}

# Initialize Faker
fake = Faker()
Faker.seed(42)
random.seed(43)

# Functions to generate fake data
def generate_hotel_reservation_data():
    hotel_reservations = []
    for basis_date in pd.date_range(start='2024-10-01', end='2024-11-15'):
        for hotel_name in hotel_amenities.keys():
            resident_cnt = fake.random_int(min=70, max=140)
            revenue = REVENUE_PER_RESIDENT * resident_cnt
            hotel_reservations.append([hotel_name, basis_date, resident_cnt, revenue])
    hotel_reservation_df = pd.DataFrame(hotel_reservations, columns=['hotel_name', 'date', 'resident_count', 'revenue'])
    hotel_reservation_df['day_of_week'] = hotel_reservation_df['date'].dt.day_name()
    return hotel_reservation_df

def randomize_usage(usage_pct, min_max_pct=0.2):
    return float(usage_pct * random.uniform(1.0 - min_max_pct, 1.0 + min_max_pct))

def get_amenity_size(hotel_name, amenity):
    return amenity_size[hotel_name].get(amenity, 10)

def generate_hotel_usage_data(hotel_reservation_df, avg_reservation_cnt_dict):
    hotel_usage_data = []
    base_df = hotel_reservation_df.loc[:, ['hotel_name', 'date', 'day_of_week']].drop_duplicates()
    for row in base_df.itertuples():
        hotel_name = row.hotel_name
        day_of_week = row.day_of_week
        date = row.date
        for amenity in hotel_amenities[hotel_name]:
            for hour, usage_pct in hour_usage_pct.items():
                usage_pct = randomize_usage(usage_pct)
                size_of_amenity = get_amenity_size(hotel_name, amenity)
                usage_cnt = int((avg_reservation_cnt_dict[(hotel_name, day_of_week)] * usage_pct) * (size_of_amenity / 100))
                hotel_usage_data.append([hotel_name, date, day_of_week, hour, amenity, usage_cnt])
    hotel_usage_df = pd.DataFrame(hotel_usage_data, columns=['hotel_name', 'date', 'day_of_week', 'hour', 'amenity', 'usage_count'])
    total_usage_hour_by_hotel_by_date = hotel_usage_df.groupby(['hotel_name', 'date'])['usage_count'].sum().reset_index()
    hotel_usage_df = hotel_usage_df.merge(total_usage_hour_by_hotel_by_date, on=['hotel_name', 'date'], suffixes=('', '_total'))
    hotel_usage_df['usage_contribution'] = hotel_usage_df['usage_count'] / hotel_usage_df['usage_count_total']
    hotel_usage_df.sort_values(by=['hotel_name', 'amenity', 'day_of_week', 'hour'], inplace=True)
    return hotel_usage_df

# Generate reservation data
hotel_reservation_df = generate_hotel_reservation_data()

# Calculate average reservation counts
avg_reservation_cnt = hotel_reservation_df.groupby(['hotel_name', 'day_of_week'])['resident_count'].mean().astype(int).reset_index()
avg_reservation_cnt_dict = avg_reservation_cnt.set_index(['hotel_name', 'day_of_week']).to_dict()['resident_count']

# Generate usage data
hotel_usage_data = generate_hotel_usage_data(hotel_reservation_df, avg_reservation_cnt_dict)
hotel_usage_data['amenity_size_m_squared'] = hotel_usage_data.apply(lambda x: get_amenity_size(x['hotel_name'], x['amenity']), axis=1)
hotel_usage_data['revenue_contribution_amt'] = hotel_usage_data['usage_contribution'] * (hotel_usage_data['usage_count_total'] * REVENUE_PER_RESIDENT)
hotel_usage_data['revenue_per_m_squared'] = hotel_usage_data['revenue_contribution_amt'] / hotel_usage_data['amenity_size_m_squared']
hotel_usage_data['resident_count'] = hotel_usage_data.apply(lambda x: avg_reservation_cnt_dict[(x['hotel_name'], x['day_of_week'])], axis=1)
# Prepare average usage data
hotel_avg_usage_df = hotel_usage_data.groupby(['hotel_name', 'amenity', 'amenity_size_m_squared', 'day_of_week', 'hour']).mean().reset_index()
hotel_avg_usage_df.drop(['usage_count_total'], axis=1, inplace=True)

# Create fake real-time data (to be replaced with actual data from Arduino)
def generate_fake_real_time_data(hotel_name, amenity, day_of_week):
    real_time_data = []
    for hour in range(24):
        usage_pct = randomize_usage(hour_usage_pct[hour])
        size_of_amenity = get_amenity_size(hotel_name, amenity)
        avg_resident_count = avg_reservation_cnt_dict[(hotel_name, day_of_week)]
        usage_cnt = int((avg_resident_count * usage_pct) * (size_of_amenity / 100))
        real_time_data.append({'hour': hour, 'usage_count': usage_cnt})
    real_time_df = pd.DataFrame(real_time_data)
    return real_time_df

# Create fake real-time data (to be replaced with actual data from Arduino)
def generate_fake_real_time_todays_data(hotel_name, amenity, day_of_week):
    real_time_data = []
    current_hour = datetime.datetime.now().hour
    # current_hour = 10
    current_dow = datetime.datetime.now().strftime('%A')
    # print(current_hour, current_dow)
    if current_dow != day_of_week:
        real_time_data.append({'hour': 0, 'usage_count': 0})
        return pd.DataFrame(real_time_data)
    for hour in range(0, current_hour + 1):
        usage_pct = randomize_usage(hour_usage_pct[hour], min_max_pct=0.7)
        size_of_amenity = get_amenity_size(hotel_name, amenity)
        avg_resident_count = avg_reservation_cnt_dict[(hotel_name, day_of_week)]
        usage_cnt = int((avg_resident_count * usage_pct) * (size_of_amenity / 100))
        # if usage_cnt > 0:
        if hour == current_hour:
            usage_cnt = usage_cnt * random.uniform(0.7, 1.5)
        to_append = {'hour': hour, 'usage_count': usage_cnt}
        # print(to_append)
        real_time_data.append(to_append)
    real_time_df = pd.DataFrame(real_time_data)
    return real_time_df

# Streamlit App
st.title("Lyf Space: Enhancing Communal Spaces through Data-Driven Insights")

# Navigation
st.sidebar.title("Navigation")
selection = st.sidebar.radio("Go to", ["For Customers", "For Hotel Management"])

if selection == "For Customers":
    st.header("Amenity Usage Insights")
    day_of_week_list = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ]
    todays_dow = datetime.datetime.now().strftime('%A')
    # Customer Filters
    st.sidebar.header("Customer Filters")
    selected_hotel = st.sidebar.selectbox("Select Hotel", options=list(hotel_amenities.keys()))
    amenity_list = hotel_amenities[selected_hotel]
    amenity_order = {
        'Bond - Social Kitchen': 1,
        'Wash & Hang - Laundromat': 2,
        'Connect - Social Co-Working Space': 3,
        'Open Connect - Social & Sip': 4,
        'Burn - Social Gym': 5,
        'Meet - Social Meeting Space': 6,
        'Colab - Social Co-Working Space': 7
    }
    amenity_list.sort(key=lambda x: amenity_order[x])
    selected_amenity = st.sidebar.selectbox("Select Amenity", options=amenity_list)
    selected_day = st.radio("Select Day of Week", options=day_of_week_list, index=day_of_week_list.index(todays_dow), horizontal=True)

    # Filter historical data
    historical_data = hotel_avg_usage_df[
        (hotel_avg_usage_df['hotel_name'] == selected_hotel) &
        (hotel_avg_usage_df['amenity'] == selected_amenity) &
        (hotel_avg_usage_df['day_of_week'] == selected_day)
        ]

    # Generate fake real-time data
    @st.fragment(run_every=5)
    def refresh_live_data():
        real_time_data = generate_fake_real_time_todays_data(selected_hotel, selected_amenity, selected_day)
        # Merge historical and real-time data
        comparison_df = pd.merge(historical_data, real_time_data, on='hour', suffixes=('_historical', '_real_time'), how='outer')
        # print(comparison_df)

        # Plotting
        st.subheader(f"Amenity Usage for {selected_amenity} on {selected_day}s at {selected_hotel}")

        comparison_long = comparison_df.melt(id_vars=['hour'], value_vars=['usage_count_historical', 'usage_count_real_time'],
                                             var_name='Type', value_name='UsageCount')
        # print(comparison_long)

        historical_bars = alt.Chart(comparison_long[comparison_long['Type'] == 'usage_count_historical']).mark_bar(
            opacity=0.8,
            color='#4B89DC',  # Softer blue
            size=25
        ).encode(
            x=alt.X('hour:Q', title='Hour of Day', scale=alt.Scale(domain=[0, 24])),
            y=alt.Y('UsageCount:Q', title='Usage Count'),
            tooltip=['hour:Q', 'UsageCount:Q']
        )

        print(comparison_long[comparison_long['Type'] == 'usage_count_real_time'])
        live_bars = alt.Chart(comparison_long[comparison_long['Type'] == 'usage_count_real_time']).mark_bar(
            opacity=0.6,
            color='#E74C3C',  # Softer red
            size=28,
            tooltip=True  # Always show tooltip
        ).encode(
            x=alt.X('hour:Q', scale=alt.Scale(domain=[0, 24])),  # Fixed x-axis range
            y=alt.Y('UsageCount:Q', title='Number of People'),
            tooltip=['hour:Q', 'UsageCount:Q']
        )
        combined_chart = (historical_bars + live_bars).properties(
            width=800,
            height=400,
            title=f"Amenity Usage for {selected_amenity} on {selected_day}s at {selected_hotel}"
        ).configure_axis(
            grid=False,
            gridColor='#EEEEEE'  # Light gray grid
        ).configure_view(
            strokeWidth=0  # Remove border
        )

        st.altair_chart(combined_chart, use_container_width=True)

    refresh_live_data()
    st.markdown("""
    **Note:** The real-time data is currently simulated and will be replaced with actual data collected from sensors.
    """)

elif selection == "For Hotel Management":
    st.header("Amenity Utilization and Revenue Optimization")

    # Management Filters
    st.sidebar.header("Management Filters")
    selected_metric = st.sidebar.selectbox(
        "Select Metric to Compare",
        options=['Usage Count', 'Usage Hours per Resident', 'Revenue per Square Meter']
    )
    selected_amenity = st.sidebar.selectbox(
        "Select Amenity",
        options=hotel_usage_data['amenity'].unique()
    )
    control_hotel = st.sidebar.selectbox(
        "Select Control Hotel",
        options=hotel_amenities.keys(),
        index=0
    )
    treatment_hotel = st.sidebar.selectbox(
        "Select Treatment Hotel",
        options=[hotel for hotel in hotel_amenities.keys() if hotel != control_hotel],
        index=0
    )

    # Filter data for selected amenity and hotels
    management_data = hotel_usage_data[
        (hotel_usage_data['amenity'] == selected_amenity) &
        (hotel_usage_data['hotel_name'].isin([control_hotel, treatment_hotel]))
        ]
    management_data.loc[:, 'usage_hours_per_resident'] = management_data['usage_count'] / management_data['resident_count']

    # Select Metric
    if selected_metric == 'Usage Count':
        metric_col = 'usage_count'
        y_title = 'Total Usage Count'
        aggregation_func = 'sum'
    elif selected_metric == 'Usage Hours per Resident':
        metric_col = 'usage_hours_per_resident'
        y_title = 'Usage Hours per Resident'
        aggregation_func = 'mean'
    else:
        metric_col = 'revenue_per_m_squared'
        y_title = 'Revenue per Square Meter ($)'
        aggregation_func = 'mean'

    # Aggregate data per hour for each hotel
    aggregated_data = management_data.groupby(['hotel_name', 'hour'])[metric_col].agg(aggregation_func).reset_index()

    # Plotting: Two Lines for Control and Treatment Hotels
    st.subheader(f"A/B Testing: Comparing {selected_metric} for {selected_amenity} between {control_hotel} and {treatment_hotel}")

    # Create Line Chart with Fixed Axes
    line_chart = alt.Chart(aggregated_data).mark_line(point=True).encode(
        x=alt.X(
            'hour:Q',
            title='Hour of Day',
            scale=alt.Scale(domain=[0, 23]),
            axis=alt.Axis(tickCount=24)
        ),
        y=alt.Y(
            f'{metric_col}:Q',
            title=y_title,
            scale=alt.Scale(domainMin=0)
        ),
        color=alt.Color('hotel_name:N', title='Hotel'),
        tooltip=['hour:Q', 'hotel_name:N', alt.Tooltip(f'{metric_col}:Q', title=selected_metric)]
    ).properties(
        width=700,
        height=400,
        title=f"{selected_metric} for {selected_amenity} at {control_hotel} vs {treatment_hotel}"
    ).interactive()

    st.altair_chart(line_chart, use_container_width=True)

    st.markdown("""
    **A/B Testing Tool:**

    Use this comparison to analyze the impact of changes made to amenities. For instance, if you've recently upgraded the **Burn - Social Gym** at **Lyf Funan**, compare its metrics with the same amenity at **Lyf Farrer** to evaluate the effectiveness of the changes.
    """)

    # Additional Data Table
    st.subheader("Detailed Metrics")
    st.dataframe(aggregated_data)

else:
    st.write("Please select a section from the navigation menu.")

# Footer
st.markdown("""
---
**Lyf Space** | Enhancing Communal Spaces through Data-Driven Insights
""")