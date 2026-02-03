# HMObservetory – Hydrological & Meteorological Observatory

Official Git Repository for the HMObservetory ecosystem. This repository represents the **Initial V1 Core** as of February 2026.

**Author:** Engineer, Rajendra Kr. Shrestha

---

## 🚀 Project Overview

HMObservetory is a professional Dart/Flutter-mobile application designed for meteorological research and high-accuracy data collection. 

This version implements the critical "Data Collector" and "Station Management" logic, ensuring geographical accuracy and standardized reporting for hydrological and meteorological analysis.

### ✨ Key Features
- **Station Mappings**: Integrated the exact collector-to-station assignments from the V1 system.
- **Rich Geographical Metadata**: Every station now exports with District, Municipality, Latitude, Longitude, and Altitude.
- **Professional 8-Row CSV Headers**: Standardized export format for seamless import into research analysis tools.
- **Hydrological Units**: All spring discharge measurements are standardized to **LPS** (Liters Per Second).

---

## 📂 Repository Structure

- **[HMObservetory/HMObservetory/](./HMObservetory/HMObservetory/)**: The active Flutter project.
- **[TASKS.md](./TASKS.md)**: Full development history and task checklist.

---

## 🛠️ Usage Instructions

### Run the App
1. Enter the project directory: `cd HMObservetory/HMObservetory`
2. Fetch dependencies: `flutter pub get`
3. Launch on device: `flutter run`

### Exporting Data
Navigate to the **View Data** screen and use the Export options. The app will generate wide-format CSV files with the 8-row metadata headers, ready for analysis.
