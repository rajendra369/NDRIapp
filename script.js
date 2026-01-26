document.addEventListener('DOMContentLoaded', () => {
    // --- Firebase Initialization ---
    const firebaseImports = window.firebaseImports;
    if (!firebaseImports) {
        alert("CRITICAL: Firebase SDK not loaded. Please checking index.html imports.");
        return;
    }
    const { initializeApp, getFirestore, collection, addDoc, getDocs, query, orderBy, onSnapshot, doc, setDoc } = firebaseImports;

    // > [!IMPORTANT]
    // > PASTE YOUR FIREBASE CONFIGURATION HERE
    // > Get this from Firebase Console -> Project Settings -> General -> Your Apps -> Web
    const firebaseConfig = {
        // Example Placeholder - REPLACE THIS with your actual keys
        apiKey: "AImSyD...REPLACE_ME",
        authDomain: "your-project.firebaseapp.com",
        projectId: "your-project-id",
        storageBucket: "your-project.appspot.com",
        messagingSenderId: "123456789",
        appId: "1:123456:web:abcdef"
    };

    let db;
    try {
        const app = initializeApp(firebaseConfig);
        db = getFirestore(app);
        console.log("Firebase Initialized");
    } catch (e) {
        console.error("Firebase Init Failed:", e);
        alert("Action Required: Please edit script.js and paste your Firebase Config keys.");
    }

    // --- Configuration ---
    // Mapped based on user image and file analysis
    const stationMapping = {
        'Chhabi Thapa': {
            flow: ['Flow_311050406']
        },
        'Niruta Purbachhane': {
            rain: ['Index_311050201', 'Index_110701_Daily', 'Index_110702_Daily'],
            flow: ['Flow_311050218', 'Flow_311050219']
        },
        'Menuka Rai': {
            rain: ['Index_311060601', 'Index_585_Daily'],
            flow: ['Flow_311050719', 'Flow_311050602']
        },
        'Yuvaraja Shrestha': {
            rain: ['Index_311060401', 'Index_1115_Daily'],
            flow: ['Flow_311060410', 'Flow_311060306']
        }
    };

    // --- Elements ---
    const form = document.getElementById('dataForm');
    const dataList = document.getElementById('dataList');
    const recordCountSpan = document.getElementById('recordCount');
    const exportRainBtn = document.getElementById('exportRainBtn');
    const exportFlowBtn = document.getElementById('exportFlowBtn');
    const dateInput = document.getElementById('date');

    const collectorSelect = document.getElementById('collector');
    const rainStationSelect = document.getElementById('rainStation');
    const flowStationSelect = document.getElementById('flowStation');

    // Sections and Toggles
    const rainSection = document.getElementById('rainSection');
    const flowSection = document.getElementById('flowSection');
    const entryTypeRadios = document.getElementsByName('entryType');

    // --- Initialization ---
    dateInput.valueAsDate = new Date();

    // Global records array for Export Functionality
    let records = [];

    // --- Firebase Logic ---

    function loadData() {
        if (!db) return;

        // Query all records, ordered by date descending
        // NOTE: If you have basic rules, ensure indexes allow this, or just get all
        const q = query(collection(db, "records")); // Client-side sort if needed or use orderBy("date", "desc")

        // Real-time listener: Updates automatically when ANYONE adds data
        onSnapshot(q, (snapshot) => {
            records = [];
            snapshot.forEach((doc) => {
                records.push({ id: doc.id, ...doc.data() });
            });
            // Client side sort since simple query is safer without creating index links
            records.sort((a, b) => new Date(b.date) - new Date(a.date));

            renderList();
        }, (error) => {
            console.error("Firestore Listen Error:", error);
            if (error.code === 'permission-denied') {
                dataList.innerHTML = '<div class="empty-state" style="color:red">Permission Denied. <br>1. Check Firebase Config.<br>2. Ensure Firestore Rules allow read/write (Test Mode).</div>';
            } else {
                dataList.innerHTML = `<div class="empty-state" style="color:red">Error: ${error.message}</div>`;
            }
        });
    }

    async function saveRecordToFirebase(record, docId) {
        if (!db) {
            alert("Firebase not initialized. Cannot save.");
            return;
        }
        try {
            // Upsert: merge: true updates existing fields if they exist, or creates new
            await setDoc(doc(db, "records", docId), record, { merge: true });

            // Success feedback
            // alert("Saved!"); // Optional: too spammy
        } catch (e) {
            console.error("Firebase Save Error:", e);
            alert("Failed to save to Cloud: " + e.message);
        }
    }

    // --- Functions ---

    // Toggle Visibility
    function handleEntryTypeChange() {
        let type = 'rain';
        for (const radio of entryTypeRadios) {
            if (radio.checked) {
                type = radio.value;
                break;
            }
        }

        if (type === 'rain') {
            rainSection.style.display = 'block';
            flowSection.style.display = 'none';
        } else {
            rainSection.style.display = 'none';
            flowSection.style.display = 'block';
        }
    }

    // Attach listeners to radios
    entryTypeRadios.forEach(radio => {
        radio.addEventListener('change', handleEntryTypeChange);
    });

    // Update Dropdowns based on Collector Selection
    collectorSelect.addEventListener('change', () => {
        const collector = collectorSelect.value;
        updateStationDropdowns(collector);
    });

    function updateStationDropdowns(collector) {
        // Clear existing options
        rainStationSelect.innerHTML = '<option value="">Select Station...</option>';
        flowStationSelect.innerHTML = '<option value="">Select Spring...</option>';

        if (!collector || !stationMapping[collector]) return;

        // Populate Rain Stations
        if (stationMapping[collector].rain) {
            stationMapping[collector].rain.forEach(station => {
                const option = document.createElement('option');
                option.value = station;
                option.textContent = station;
                rainStationSelect.appendChild(option);
            });
        }


        // Populate Flow Stations
        if (stationMapping[collector].flow) {
            stationMapping[collector].flow.forEach(station => {
                const option = document.createElement('option');
                option.value = station;
                option.textContent = station;
                flowStationSelect.appendChild(option);
            });
        }
    }

    function renderList() {
        dataList.innerHTML = '';
        recordCountSpan.textContent = `${records.length} records`;

        if (records.length === 0) {
            dataList.innerHTML = '<div class="empty-state">No data found in Cloud.</div>';
            return;
        }

        records.forEach(record => {
            const item = document.createElement('div');
            item.className = 'data-item';

            let details = '';
            // Only show what was recorded
            if (record.rainStation && record.rainfall) {
                details += `<div><strong>Rain:</strong> ${record.rainfall}mm <small>(${record.rainStation})</small></div>`;
            }
            if (record.flowStation && record.discharge) {
                details += `<div><strong>Flow:</strong> ${record.discharge}LPS <small>(${record.flowStation})</small></div>`;
            }

            item.innerHTML = `
                <div class="data-info">
                    <span class="data-date">${formatDate(record.date)}</span>
                    <div style="font-size: 0.8rem; color: #64748b; margin-bottom:4px;">Collector: ${record.collector}</div>
                    <div class="data-values" style="display:block;">
                        ${details || 'Empty Record'}
                    </div>
                </div>
            `;
            dataList.appendChild(item);
        });
    }

    function formatDate(dateString) {
        const options = { year: 'numeric', month: 'short', day: 'numeric' };
        return new Date(dateString).toLocaleDateString(undefined, options);
    }

    // --- Event Listeners ---

    form.addEventListener('submit', (e) => {
        e.preventDefault();

        const collector = collectorSelect.value;
        const date = document.getElementById('date').value;

        // Determine Mode
        let mode = 'rain';
        for (const radio of entryTypeRadios) {
            if (radio.checked) {
                mode = radio.value;
                break;
            }
        }

        // Validation & Data Prep
        let newRainStation = null, newRainfall = null;
        let newFlowStation = null, newDischarge = null;

        if (mode === 'rain') {
            newRainStation = document.getElementById('rainStation').value;
            newRainfall = document.getElementById('rainfall').value;
            if (!newRainStation || !newRainfall) {
                alert("Please select a Rain Station and enter rainfall amount.");
                return;
            }
        } else {
            newFlowStation = document.getElementById('flowStation').value;
            newDischarge = document.getElementById('discharge').value;
            if (!newFlowStation || !newDischarge) {
                alert("Please select a Spring/Stream and enter discharge amount.");
                return;
            }
        }

        // --- PREPARE DATA ---
        // Create a Unique ID for upsert: "DATE_STATION"
        // This ensures we don't get duplicates for the same station on the same day.
        const stationKey = mode === 'rain' ? newRainStation : newFlowStation;
        // Sanitize ID just in case (remove spaces etc if needed, but station names look safe-ish)
        // Let's use a safe format: "YYYY-MM-DD_StationName"
        const docId = `${date}_${stationKey.replace(/[^a-zA-Z0-9_-]/g, '')}`;

        const newRecord = {
            date: date,
            collector: collector,
            lastUpdated: new Date().toISOString()
        };

        if (mode === 'rain') {
            newRecord.rainStation = newRainStation;
            newRecord.rainfall = newRainfall;
            // Clear flow keys if we want strict separation, or merge handled by Firestore
        } else {
            newRecord.flowStation = newFlowStation;
            newRecord.discharge = newDischarge;
        }

        // Save to Firebase (this will trigger onSnapshot -> renderList)
        saveRecordToFirebase(newRecord, docId);

        // Reset inputs
        if (mode === 'rain') {
            document.getElementById('rainfall').value = '';
        } else {
            document.getElementById('discharge').value = '';
        }
    });

    // Generic Export Function with Metadata Headers
    function exportWideCSV(type) {
        if (records.length === 0) {
            alert('No data to export!');
            return;
        }

        const isRain = type === 'rain';

        // 1. Identify valid stations for this type across all records logic
        const allStations = new Set();
        // Add known stations from mapping (to ensure order/existence)
        Object.values(stationMapping).forEach(group => {
            const list = isRain ? group.rain : group.flow;
            if (list) list.forEach(s => allStations.add(s));
        });

        const stationColumns = Array.from(allStations).sort();

        if (stationColumns.length === 0) {
            alert(`No ${type} data found to export.`);
            return;
        }

        let csvContent = "";

        // --- HEADER GENERATION (8 Rows) ---
        // Rows: District, Muni, Loc, Lat, Lon, Alt, Collector, Index

        const headers = [
            { key: 'region', label: 'District' },
            { key: 'muni', label: 'Municipality/Ward' },
            { key: 'loc', label: 'Location Description' },
            { key: 'lat', label: 'Latitude (*N)' },
            { key: 'lon', label: 'Longitude (*E)' },
            { key: 'alt', label: 'Altitude (m)' },
            { key: 'collector', label: 'Data collector (Name & Contact)' },
            { key: 'self', label: 'Date A.D.' } // The row that contains station names
        ];

        headers.forEach(h => {
            const rowArr = [h.label];
            stationColumns.forEach(st => {
                if (h.key === 'self') {
                    rowArr.push(st);
                } else {
                    // Check metadata
                    const meta = stationMetadata[st] || {};
                    rowArr.push(meta[h.key] || '');
                }
            });
            csvContent += rowArr.join(",") + "\n";
        });

        // --- DATA ROWS ---
        // Pivot Data
        const pivotData = {};
        records.forEach(r => {
            if (!pivotData[r.date]) pivotData[r.date] = {};

            if (isRain && r.rainStation && r.rainfall) {
                pivotData[r.date][r.rainStation] = r.rainfall;
            }
            if (!isRain && r.flowStation && r.discharge) {
                pivotData[r.date][r.flowStation] = r.discharge;
            }
        });

        const sortedDates = Object.keys(pivotData).sort();

        sortedDates.forEach(date => {
            const rowData = pivotData[date];
            // Check if row has data for these stations
            const hasData = stationColumns.some(st => rowData[st] !== undefined);

            if (hasData) {
                const rowValues = [date];
                stationColumns.forEach(station => {
                    const val = rowData[station];
                    rowValues.push(val !== undefined ? val : "");
                });
                csvContent += rowValues.join(",") + "\n";
            }
        });

        // Download
        const filename = isRain ? 'rainfall_data_wide.csv' : 'discharge_data_wide.csv';
        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.setAttribute('href', url);
        link.setAttribute('download', filename);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    if (exportRainBtn) exportRainBtn.addEventListener('click', () => exportWideCSV('rain'));
    if (exportFlowBtn) exportFlowBtn.addEventListener('click', () => exportWideCSV('flow'));

    // Initial render
    loadData(); // Load from API on backend
    handleEntryTypeChange(); // Initialize visibility
});
