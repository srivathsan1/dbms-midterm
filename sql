# frontend_fitness.py
# This file serves as the Streamlit frontend for the Fitness Tracker application.

import streamlit as st
import pandas as pd
import datetime
from backend import (
    create_tables, create_user, get_user_by_email, add_friend,
    remove_friend, get_friends, log_workout, get_user_workouts,
    set_goal, get_user_goals, get_leaderboard_data
)

# --- Initialize Database and Page ---
create_tables()

st.set_page_config(
    page_title="Personal Fitness Tracker",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.title("💪 Personal Fitness Tracker")
st.markdown("Track your workouts, set goals, and compete with friends.")

# --- Session State for User Management ---
# Use session state to store the current user's email and ID
if 'current_user_id' not in st.session_state:
    st.session_state.current_user_id = None
if 'current_user_email' not in st.session_state:
    st.session_state.current_user_email = None

# --- User Login/Registration ---
st.sidebar.header("User Profile")
user_email = st.sidebar.text_input("Enter your email to log in or register:")
if st.sidebar.button("Submit"):
    user = get_user_by_email(user_email)
    if user:
        st.session_state.current_user_id = user[0]
        st.session_state.current_user_email = user[2]
        st.sidebar.success(f"Welcome back, {user[1]}!")
    else:
        st.session_state.current_user_id = None
        st.sidebar.info("User not found. Please register below.")
        with st.sidebar.expander("Register New User"):
            with st.form("register_form"):
                name = st.text_input("Name")
                email = st.text_input("Email", value=user_email)
                weight = st.number_input("Weight (kg)", min_value=1.0, step=0.1)
                if st.form_submit_button("Register"):
                    success, message, user_id = create_user(name, email, weight)
                    if success:
                        st.session_state.current_user_id = user_id
                        st.session_state.current_user_email = email
                        st.sidebar.success(message)
                    else:
                        st.sidebar.error(message)

# Main App Logic - only visible if a user is logged in
if st.session_state.current_user_id:
    st.sidebar.success(f"Logged in as: {st.session_state.current_user_email}")
    st.markdown("---")

    # --- Leaderboard Section ---
    st.header("📊 Leaderboard")
    st.subheader("Total Workout Minutes This Week")
    leaderboard_data = get_leaderboard_data(st.session_state.current_user_id)
    if leaderboard_data:
        df_leaderboard = pd.DataFrame(leaderboard_data, columns=["Name", "Total Minutes"])
        df_leaderboard.index = range(1, len(df_leaderboard) + 1)
        st.dataframe(df_leaderboard, use_container_width=True)
    else:
        st.info("No leaderboard data yet. Log a workout or add friends!")
    
    st.markdown("---")

    # --- Log Workout Section ---
    st.header("🏋️ Log a New Workout")
    with st.form("workout_form", clear_on_submit=True):
        workout_date = st.date_input("Workout Date", datetime.date.today())
        duration_minutes = st.number_input("Duration (minutes)", min_value=1, step=1)

        st.subheader("Exercises")
        num_exercises = st.number_input("Number of Exercises", min_value=1, step=1)
        exercises = []
        for i in range(num_exercises):
            with st.expander(f"Exercise #{i+1}"):
                exercise_name = st.text_input("Exercise Name", key=f"ex_name_{i}")
                reps = st.number_input("Reps", min_value=0, key=f"reps_{i}")
                sets = st.number_input("Sets", min_value=0, key=f"sets_{i}")
                weight = st.number_input("Weight (kg)", min_value=0.0, step=0.1, key=f"weight_{i}")
                exercises.append((exercise_name, reps, sets, weight))

        submitted = st.form_submit_button("Log Workout")
        if submitted:
            success, message = log_workout(st.session_state.current_user_id, workout_date, duration_minutes, exercises)
            if success:
                st.success(message)
                st.rerun()
            else:
                st.error(message)

    st.markdown("---")

    # --- My Workouts & Goals Section (in sidebar for clean layout) ---
    with st.sidebar.expander("My Workouts"):
        st.subheader("Workout History")
        workouts = get_user_workouts(st.session_state.current_user_id)
        if workouts:
            df_workouts = pd.DataFrame(workouts, columns=["Date", "Duration (minutes)"])
            st.dataframe(df_workouts)
        else:
            st.info("No workouts logged yet.")
    
    with st.sidebar.expander("Set Goals"):
        st.subheader("Set a New Goal")
        with st.form("goal_form", clear_on_submit=True):
            goal_description = st.text_area("Goal Description")
            target_value = st.number_input("Target Value", min_value=0.0, step=0.1)
            submitted_goal = st.form_submit_button("Set Goal")
            if submitted_goal:
                success, message = set_goal(st.session_state.current_user_id, goal_description, target_value)
                if success:
                    st.success(message)
                else:
                    st.error(message)

    with st.sidebar.expander("My Goals"):
        st.subheader("Your Goals")
        goals = get_user_goals(st.session_state.current_user_id)
        if goals:
            for goal in goals:
                status = "✅" if goal[2] else "⏳"
                st.write(f"{status} **Goal:** {goal[0]} - **Target:** {goal[1]}")
        else:
            st.info("No goals set yet.")
            
    # --- Friend Management Section (in sidebar) ---
    with st.sidebar.expander("Friends"):
        st.subheader("Manage Friends")
        friend_email_input = st.text_input("Friend's email:")
        col_fr1, col_fr2 = st.columns(2)
        with col_fr1:
            if st.button("Add Friend"):
                success, message = add_friend(st.session_state.current_user_id, friend_email_input)
                if success:
                    st.success(message)
                    st.rerun()
                else:
                    st.error(message)
        with col_fr2:
            if st.button("Remove Friend"):
                success, message = remove_friend(st.session_state.current_user_id, friend_email_input)
                if success:
                    st.success(message)
                    st.rerun()
                else:
                    st.error(message)
        
        st.subheader("My Friend List")
        friends = get_friends(st.session_state.current_user_id)
        if friends:
            df_friends = pd.DataFrame(friends, columns=["Name", "Email"])
            st.dataframe(df_friends, use_container_width=True)
        else:
            st.info("You have no friends yet. Add some to get the leaderboard running!")

else:
    st.info("Please enter your email in the sidebar to log in or register.")
