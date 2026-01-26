import pandas as pd
import os

files = [
    r"C:\Users\raj10\Desktop\app\Precipitation_Raw.xlsx",
    r"C:\Users\raj10\Desktop\app\Stream Flow_Raw.xlsx"
]

for f in files:
    print(f"--- File: {os.path.basename(f)} ---")
    try:
        xl = pd.ExcelFile(f)
        print(xl.sheet_names)
    except Exception as e:
        print(f"Error: {e}")
