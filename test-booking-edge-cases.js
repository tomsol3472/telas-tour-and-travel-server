const http = require('http');

const PORT = process.env.PORT || 5000;
const TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZmYzI2MDE4LTFiNzgtNGM3MC05MGE3LWQwMGI0ODUwMTVjYSIsImlhdCI6MTc3NDU5OTM2OCwiZXhwIjoxNzc3MTkxMzY4fQ.MJP3OrF9NoYj0gWhKXkBn8oBQRgFRZB2_RroDhfRKB0";

function makeRequest(testName, payload) {
    return new Promise((resolve) => {
        const data = JSON.stringify(payload);
        const options = {
            hostname: 'localhost',
            port: PORT,
            path: '/api/bookings',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${TOKEN}`,
                'Content-Length': Buffer.byteLength(data)
            }
        };

        const req = http.request(options, (res) => {
            let responseBody = '';
            res.on('data', (chunk) => responseBody += chunk);
            res.on('end', () => {
                console.log(`\n--- Test: ${testName} ---`);
                console.log(`Payload: ${data}`);
                console.log(`Status Code: ${res.statusCode}`);
                console.log(`Response: ${responseBody}`);
                resolve();
            });
        });

        req.on('error', (e) => {
            console.error(`\n--- Test: ${testName} ---`);
            console.error(`Problem with request: ${e.message}`);
            resolve();
        });

        req.write(data);
        req.end();
    });
}

async function runTests() {
    console.log("Starting Booking Edge Case Tests...");

    // Test 1: Invalid package_id ("14") - Should be sanitized to null and succeed
    await makeRequest("Invalid package_id ('14')", {
        package_id: "14",
        start_date: "2026-04-01",
        end_date: "2026-04-05",
        adults: 2,
        origin: "Addis Ababa",
        destination: "Lalibela"
    });

    // Test 2: Missing package_id (Null) - Should succeed as package_id is optional
    await makeRequest("Missing package_id (null)", {
        package_id: null,
        start_date: "2026-04-10",
        end_date: "2026-04-15",
        adults: 1,
        origin: "Addis Ababa",
        destination: "Gondar"
    });

    // Test 3: Constraint check - end_date before start_date
    await makeRequest("End Date Before Start Date", {
        package_id: null,
        start_date: "2026-05-10",
        end_date: "2026-05-05",
        adults: 2,
        origin: "Addis Ababa",
        destination: "Bahir Dar"
    });

    // Test 4: Missing Origin/Destination details
    await makeRequest("Missing Missing Origin", {
        package_id: null,
        start_date: "2026-06-01",
        end_date: "2026-06-05",
        adults: 1,
        destination: "Bahir Dar"
    });

    console.log("\nFinished tests.");
}

runTests();
