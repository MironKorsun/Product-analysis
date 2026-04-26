# Portfolio: Product Analyst Internship
# Miron Korsun

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

np.random.seed(42)

# --------------------------------------------------
# 1. Generate sample dataset
# --------------------------------------------------
n = 500

# исправлено: correct как float, чтобы nan проходил
correct_vals = np.random.poisson(40, n).astype(float)

for _ in range(20):
    idx = np.random.randint(0, n)
    correct_vals[idx] = np.nan

data = {
    'user_id': range(1, n + 1),
    'grade': np.random.randint(1, 12, n),
    'lessons': np.random.poisson(20, n),
    'time_min': np.random.exponential(120, n).astype(int),
    'tasks': np.random.poisson(45, n),
    'correct': correct_vals,
    'region': np.random.choice(['Moscow', 'SPb', 'Region', 'Other'], n, p=[0.3, 0.2, 0.4, 0.1])
}

df = pd.DataFrame(data)
df['accuracy'] = df['correct'] / df['tasks']

# --------------------------------------------------
# 2. Clean missing values
# --------------------------------------------------
df['correct'] = df['correct'].fillna(df['correct'].median())
df['accuracy'] = df['correct'] / df['tasks']

# --------------------------------------------------
# 3. Regional activity
# --------------------------------------------------
regional = df.groupby('region').agg({
    'user_id': 'count',
    'lessons': 'mean',
    'time_min': 'mean',
    'tasks': 'mean'
}).round(1)
regional.columns = ['users', 'avg_lessons', 'avg_time', 'avg_tasks']
regional = regional.sort_values('users', ascending=False)

print("=== Users by Region ===")
print(regional)
print("\n")

fig, ax = plt.subplots(figsize=(10, 4))
regional['users'].plot(kind='bar', ax=ax, color='steelblue')
ax.set_title('Users by Region')
ax.set_ylabel('Count')
plt.tight_layout()
plt.savefig('users_by_region.png')
plt.show()

# --------------------------------------------------
# 4. Accuracy by grade
# --------------------------------------------------
grade_stats = df.groupby('grade')['accuracy'].mean().reset_index()

print("=== Accuracy by Grade ===")
print(grade_stats)
print("\n")

fig, ax = plt.subplots(figsize=(10, 4))
ax.plot(grade_stats['grade'], grade_stats['accuracy'], marker='o', color='darkgreen')
ax.set_title('Average Accuracy by Grade')
ax.set_xlabel('Grade')
ax.set_ylabel('Accuracy')
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig('accuracy_by_grade.png')
plt.show()

corr_grade_acc = df['grade'].corr(df['accuracy'])
print(f"Grade-Accuracy correlation: {corr_grade_acc:.2f}\n")

# --------------------------------------------------
# 5. Engagement distribution
# --------------------------------------------------
fig, axes = plt.subplots(1, 3, figsize=(15, 4))

df['lessons'].hist(bins=25, ax=axes[0], color='coral', edgecolor='black')
axes[0].set_title('Lessons Completed')

df['time_min'].hist(bins=25, ax=axes[1], color='skyblue', edgecolor='black')
axes[1].set_title('Time Spent (minutes)')

df['accuracy'].hist(bins=25, ax=axes[2], color='seagreen', edgecolor='black')
axes[2].set_title('Accuracy Distribution')

plt.tight_layout()
plt.savefig('distribution.png')
plt.show()

# --------------------------------------------------
# 6. Pareto (80/20) analysis
# --------------------------------------------------
sorted_df = df.sort_values('tasks', ascending=False)
sorted_df['cum_users_pct'] = (np.arange(len(sorted_df)) + 1) / len(sorted_df) * 100
sorted_df['cum_tasks_pct'] = sorted_df['tasks'].cumsum() / sorted_df['tasks'].sum() * 100

top20_users = sorted_df[sorted_df['cum_users_pct'] <= 20]
top20_contribution = top20_users['tasks'].sum() / df['tasks'].sum() * 100

fig, ax1 = plt.subplots(figsize=(10, 5))

ax1.bar(sorted_df['cum_users_pct'], sorted_df['tasks'], width=1.5, alpha=0.6, color='royalblue')
ax1.set_xlabel('Cumulative % of Users')
ax1.set_ylabel('Tasks per User', color='blue')
ax1.tick_params(axis='y', labelcolor='blue')

ax2 = ax1.twinx()
ax2.plot(sorted_df['cum_users_pct'], sorted_df['cum_tasks_pct'], color='red', linewidth=2)
ax2.set_ylabel('Cumulative % of Tasks', color='red')
ax2.tick_params(axis='y', labelcolor='red')

plt.title(f'Pareto: Top 20% users -> {top20_contribution:.1f}% of tasks')
plt.axhline(y=80, color='gray', linestyle='--', alpha=0.5)
plt.axvline(x=20, color='gray', linestyle='--', alpha=0.5)
plt.tight_layout()
plt.savefig('pareto.png')
plt.show()

print(f"Top 20% task contribution: {top20_contribution:.1f}%\n")

# --------------------------------------------------
# 7. Correlation matrix
# --------------------------------------------------
numeric_cols = ['grade', 'lessons', 'time_min', 'tasks', 'correct', 'accuracy']
corr = df[numeric_cols].corr()

print("=== Correlation Matrix ===")
print(corr)
print("\n")

fig, ax = plt.subplots(figsize=(8, 6))
sns.heatmap(corr, annot=True, cmap='coolwarm', center=0, fmt='.2f', ax=ax)
ax.set_title('Correlation Matrix')
plt.tight_layout()
plt.savefig('correlation_matrix.png')
plt.show()

# --------------------------------------------------
# 8. Summary
# --------------------------------------------------
print("=== SUMMARY ===")
print(f"Total users: {len(df)}")
print(f"Regions: {list(df['region'].unique())}")
print(f"Average accuracy: {df['accuracy'].mean():.2f}")
print(f"Median lessons: {df['lessons'].median():.0f}")
print(f"Median time: {df['time_min'].median():.0f} min")
