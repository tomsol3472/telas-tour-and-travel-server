const axios = require('axios');
(async () => {
    try {
        const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjI5OGUyY2ZlLTRjNTQtNGI2MS1hOGI0LTQyY2VjYjg2M2VlYyIsImlhdCI6MTc3NDU5ODgyMCwiZXhwIjoxNzc3MTkwODIwfQ.LUuVdqu8TjoOy1YYGcSCik-q4WVd5tCwQ2ZJmMaJeSA";
        const res = await axios.post('http://localhost:5000/api/bookings', {
            package_id: null,
            start_date: "2026-05-01",
            end_date: "2026-05-10",
            adults: 2,
            origin: "Addis Ababa",
            destination: "Lalibela"
        }, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        });
        console.log(res.data);
    } catch (e) {
        console.error(e.response?.data || e.message);
    }
})();
