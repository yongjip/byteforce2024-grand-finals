import streamlit as st
import datetime
import pandas as pd
import numpy as np
import time
import altair as alt
import random
import faker

"""
1. fake hotel reservation data
2. fake avg usage data for hotel amenities
3. fake hotel amenity size data

"""
hour_usage_pct = {
    0: 0.1,
    1: 0.1,
    2: 0.05,
    3: 0.03,
    4: 0.02,
    5: 0.01,
    6: 0.02,
    7: 0.03,
    8: 0.03,
    9: 0.05,
    10: 0.1,
    11: 0.1,
    12: 0.2,
    13: 0.2,
    14: 0.2,
    15: 0.2,
    16: 0.2,
    17: 0.2,
    18: 0.2,
    19: 0.2,
    20: 0.1,
    21: 0.1,
    22: 0.1,
    23: 0.1
}

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

REVENUE_PER_RESIDENT = 100
REVENUE_PER_HOUR_AMENITY_USAGE = REVENUE_PER_RESIDENT/24



def generate_hotel_reservation_data():
    hotel_reservations = []

    faker.Faker.seed(42)
    fake = faker.Faker()

    for basis_date in pd.date_range(start='2024-10-01', end='2024-11-15'):
        for hotel_name in hotel_amenities.keys():
            resident_cnt = fake.random_int(min=70, max=140)
            hotel_reservations.append([hotel_name, basis_date, resident_cnt, REVENUE_PER_RESIDENT * resident_cnt])

    hotel_reservation_df = pd.DataFrame(hotel_reservations, columns=['hotel_name', 'date', 'resident_count', 'revenue'])
    hotel_reservation_df['day_of_week'] = hotel_reservation_df['date'].dt.day_name()
    return hotel_reservation_df

def randomize_usage(usage_pct, min_max_pct=0.2):
    return float(usage_pct * random.uniform(1.0 - min_max_pct, 1.0 + min_max_pct))

def get_amenity_size(hotel_name, amenity):
    return amenity_size[hotel_name].get(amenity, 10)


# create hotel amenity avg usage by hour data
def generate_hotel_usage_data():
    hotel_usage_data = []
    seed = 43
    random.seed(seed)
    base_df = hotel_reservation_df.loc[:, ['hotel_name', 'date', 'day_of_week']].drop_duplicates()

    for row in base_df.itertuples():
        hotel_name = row.hotel_name
        day_of_week = row.day_of_week
        date = row.date
        for amenity in hotel_amenities[hotel_name]:
            for hour, usage_pct in hour_usage_pct.items():
                usage_pct = randomize_usage(usage_pct)
                size_of_amenity = get_amenity_size(hotel_name, amenity)
                usage_cnt = int((avg_reservation_cnt_dict[hotel_name, day_of_week] * usage_pct) * (size_of_amenity / 100))
                # revenue_contribution_amt = REVENUE_PER_HOUR_AMENITY_USAGE * usage_cnt
                hotel_usage_data.append([hotel_name, date, day_of_week, hour, amenity, usage_cnt])
    hotel_usage_df = pd.DataFrame(hotel_usage_data, columns=['hotel_name', 'date', 'day_of_week', 'hour', 'amenity', 'usage_count'])
    total_usage_hour_by_hotel_by_date = hotel_usage_df.groupby(['hotel_name', 'date'])['usage_count'].sum().reset_index()
    # usage_contribution = usage_cnt / total_usage_hour_by_hotel_by_date['usage_count']
    hotel_usage_df = hotel_usage_df.merge(total_usage_hour_by_hotel_by_date, on=['hotel_name', 'date'], suffixes=('', '_total'))
    hotel_usage_df.loc[:, 'usage_contribution'] = hotel_usage_df['usage_count'] / hotel_usage_df['usage_count_total']
    hotel_usage_df.sort_values(by=['hotel_name', 'amenity', 'day_of_week', 'hour'], inplace=True)
    return hotel_usage_df

hotel_reservation_df = generate_hotel_reservation_data()
avg_reservation_cnt = hotel_reservation_df.groupby(['hotel_name', 'day_of_week'])['resident_count'].mean().astype(int).reset_index()
avg_reservation_cnt_dict = avg_reservation_cnt.set_index(['hotel_name', 'day_of_week']).to_dict()['resident_count']

hotel_usage_data = generate_hotel_usage_data()
hotel_usage_data.loc[:, 'amenity_size_m_squared'] = hotel_usage_data.apply(lambda x: get_amenity_size(x['hotel_name'], x['amenity']), axis=1)
hotel_usage_data.loc[:, 'revenue_contribution_amt'] = hotel_usage_data['usage_contribution'] * (hotel_usage_data['usage_count_total'] * REVENUE_PER_RESIDENT)
hotel_usage_data.loc[:, 'revenue_per_m_squared'] = hotel_usage_data['revenue_contribution_amt'] / hotel_usage_data['amenity_size_m_squared']
# hotel_avg_usage_df = hotel_usage_data.groupby(['hotel_name', 'amenity', 'amenity_size_m_squared', 'day_of_week', 'hour'])['usage_count'].mean().astype(int).reset_index()


# Generate fake data for hotel_amenities
hotel_usage_data.to_clipboard()
print(hotel_usage_data)

"""
columns
usage_count: number of people using the amenity
usage_contribution: percentage of total amenity usage for the hotel on that day
revenue_contribution_amt: revenue contribution from the amenity usage
revenue_per_m_squared: revenue per square meter of the amenity
amenity_size_m_squared: size of the amenity in square meters

"""

# def generate_live_data():
#     faker.Faker.seed(42)
#     fake = faker.Faker()
#     current_hour = datetime.datetime.now().hour
#     current_day = datetime.datetime.now().strftime('%A')
#     current_usage = fake.random_int(min=10, max=25)
#     return current_day, current_hour, current_usage
#
#
# faker.Faker.seed(50)
# fake = faker.Faker()
#
# st.title("Restaurant Usage Patterns")
# # Generate historical data - use session state to persist data
# if 'historical_df' not in st.session_state:
#     st.session_state.historical_df = hotel_avg_usage_df
#
# # Day selection
# day_of_week_list = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
# hotel_list = ['Lyf Funan', 'Lyf Farrer']
# amenity_list = ['Connect - Social Co-Working Space', 'Open Connect - Social & Sip', 'Bond - Social Kitchen', 'Burn - Social Gym', 'Wash & Hang - Laundromat', 'Meet - Social Meeting Space', 'Colab - Social Co-Working Space']
#
# selected_day = st.radio("Select Day of Week:", day_of_week_list, horizontal=True)
# selected_hotel = st.radio("Select Hotel:", hotel_list, horizontal=True)
# selected_amenity = st.radio("Select Amenity:", amenity_list, horizontal=True)
# day_data = st.session_state.historical_df[(st.session_state.historical_df['day_of_week'] == selected_day) & (st.session_state.historical_df['hotel_name'] == selected_hotel)]
#
#
# # Create data for chart
# cond = (hotel_avg_usage_df['day_of_week'] == selected_day) & (hotel_avg_usage_df['hotel_name'] == selected_hotel) & (hotel_avg_usage_df['amenity'] == selected_amenity)
# # print(hotel_avg_usage_df[cond])
# historical_usage = []
# for hour in range(0, 24):
#     usage = hotel_avg_usage_df[cond & (hotel_avg_usage_df['hour'] == hour)]['usage_count']
#     historical_usage.append(usage.iloc[0] if not usage.empty else 0)
#
# chart_data = pd.DataFrame({
#     'Hour': range(0, 24),
#     'Historical Usage': historical_usage,
# })
#
# @st.fragment(run_every=5)
# def refresh_live_data():
#
#     #st.session_state.last_refresh = time.time()
#     st.session_state.current_day, st.session_state.current_hour, st.session_state.current_usage = generate_live_data()
#     st.session_state.selected_hotel = selected_hotel
#     st.session_state.selected_amenity = selected_amenity
#
#     status=""
#     refresh_data=chart_data
#     # Add live data if current day matches selected day
#     if (st.session_state.current_day == selected_day) & (st.session_state.selected_hotel == selected_hotel) & (st.session_state.selected_amenity == selected_amenity):
#
#         refresh_data.loc[refresh_data['Hour'] == st.session_state.current_hour, 'Live Usage'] = st.session_state.current_usage
#         cond = (hotel_avg_usage_df['day_of_week'] == selected_day) & (hotel_avg_usage_df['hotel_name'] == selected_hotel) & (hotel_avg_usage_df['amenity'] == selected_amenity)
#         historical_avg = hotel_avg_usage_df[cond]['usage_count'].iloc[0]
#         status = "busier than usual" if st.session_state.current_usage > historical_avg else "less busy than usual"
#     # Melt the dataframe for Altair
#     melted_data = pd.melt(refresh_data, id_vars=['Hour'], var_name='Type', value_name='Usage')
#
#     # Create overlapping bar chart with Altair - with improved styling
#     historical_bars = alt.Chart(melted_data[melted_data['Type'] == 'Historical Usage']).mark_bar(
#         opacity=0.8,
#         color='#4B89DC',  # Softer blue
#         size=25
#     ).encode(
#         x=alt.X('Hour:Q', scale=alt.Scale(domain=[0, 24])),  # Fixed x-axis range
#         y=alt.Y('Usage:Q', title='Number of People'),
#         tooltip=['Hour:Q', 'Usage:Q']
#     )
#
#     live_bars = alt.Chart(melted_data[melted_data['Type'] == 'Live Usage']).mark_bar(
#         opacity=0.6,
#         color='#E74C3C',  # Softer red
#         size=28,
#         tooltip=True  # Always show tooltip
#     ).encode(
#         x=alt.X('Hour:Q', scale=alt.Scale(domain=[0, 24])),  # Fixed x-axis range
#         y=alt.Y('Usage:Q', title='Number of People'),
#         tooltip=['Hour:Q', 'Usage:Q']
#     )
#
#     chart = (historical_bars + live_bars).properties(
#         width=800,
#         height=400,
#         title=f"Hourly Usage Pattern({status})"
#     ).configure_axis(
#         grid=False,
#         gridColor='#EEEEEE'  # Light gray grid
#     ).configure_view(
#         strokeWidth=0  # Remove border
#     )
#
#     st.altair_chart(chart)
#     st.write(status)
#
#
# refresh_live_data()
