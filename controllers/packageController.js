const db = require('../config/db');

const safeJSONParse = (jsonString, fallback = []) => {
    if (!jsonString) return fallback;
    try { return JSON.parse(jsonString); } catch (e) { return fallback; }
};

exports.createPackage = async (req, res) => {
    try {
        const { package_code, name, description, tour_type, difficulty, season_recommendation, important_notes, cancellation_policy } = req.body;
        
        const duration_days = parseInt(req.body.duration_days) || 1;
        const duration_nights = parseInt(req.body.duration_nights) || 0;
        const min_group_size = parseInt(req.body.min_group_size) || 1;
        const max_group_size = parseInt(req.body.max_group_size) || 15;
        
        // Pricing
        const price_international = parseFloat(req.body.price_per_person_international) || 0;
        const price_local = parseFloat(req.body.price_per_person_local) || 0; 
        const price_diaspora = parseFloat(req.body.price_per_person_diaspora) || 0;
        const child_discount = parseFloat(req.body.child_discount_percentage) || 0;
        const infant_discount = parseFloat(req.body.infant_discount_percentage) || 0;
        const group_discount = parseFloat(req.body.group_discount_percentage) || 0;
        const season = req.body.season || 'both';

        const is_active = req.body.is_active === 'true';
        const is_customizable = req.body.is_customizable === 'true';

        // Arrays parsed from FormData
        const tags = safeJSONParse(req.body.tags, []);
        const inclusions = safeJSONParse(req.body.inclusions, ['Guide']);
        const exclusions = safeJSONParse(req.body.exclusions, []);
        const requirements = safeJSONParse(req.body.requirements, []);
        const itinerary = safeJSONParse(req.body.itinerary, []);
        
        // Images (Combine existing and newly uploaded ones)
        let photos_urls = safeJSONParse(req.body.photos_urls, []);
        if (req.files && req.files.length > 0) {
            const uploadedFilePaths = req.files.map(file => `/uploads/${file.filename}`);
            photos_urls = [...photos_urls, ...uploadedFilePaths];
        }

        const created_by = req.user ? req.user.userId : null;

        await db.query('BEGIN'); // Start Transaction

        // 1. Insert into tour_packages
        const pkgResult = await db.query(
            `INSERT INTO tour_packages 
            (package_code, name, description, tour_type, difficulty, duration_days, duration_nights, 
             min_group_size, max_group_size, season_recommendation, tags, inclusions, exclusions, 
             requirements, important_notes, cancellation_policy, photos_urls, is_customizable, created_by, is_active)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
            RETURNING id`,
            [package_code, name, description, tour_type, difficulty, duration_days, duration_nights, min_group_size, max_group_size, season_recommendation, tags, inclusions, exclusions, requirements, important_notes, cancellation_policy, photos_urls, is_customizable, created_by, is_active]
        );

        const packageId = pkgResult.rows[0].id;

        // 2. Insert into package_pricing
        await db.query(
            `INSERT INTO package_pricing 
            (package_id, season, price_per_person_international, price_per_person_local, price_per_person_diaspora, child_discount_percentage, infant_discount_percentage, group_discount_percentage) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, 
            [packageId, season, price_international, price_local, price_diaspora, child_discount, infant_discount, group_discount]
        );

        // 3. Insert into package_itineraries
        for (let day of itinerary) {
            await db.query(
                `INSERT INTO package_itineraries 
                (package_id, day_number, title, description, accommodation_type, meal_plan, distance_km, travel_time_hours) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
                [packageId, day.day_number || 1, day.title || `Day ${day.day_number}`, day.description || '', day.accommodation_type || '', day.meal_plan || '', parseFloat(day.distance_km) || 0, parseFloat(day.travel_time_hours) || 0]
            );
        }

        await db.query('COMMIT'); // Save Transaction
        res.status(201).json({ message: "Package created successfully" });
    } catch (err) {
        await db.query('ROLLBACK');
        res.status(500).json({ error: "Failed to create package", details: err.message });
    }
};

exports.getAllPackages = async (req, res) => {
    try {
        // Removed hardcoded CORS headers to rely on global CORS middleware
        
        const result = await db.query(
            `SELECT 
                tp.*, 
                pp.season, pp.price_per_person_international, pp.price_per_person_local, pp.price_per_person_diaspora,
                pp.child_discount_percentage, pp.infant_discount_percentage, pp.group_discount_percentage,
                COALESCE(pp.price_per_person_international, 0) AS base_price,
                (SELECT json_agg(pi.* ORDER BY pi.day_number) FROM package_itineraries pi WHERE pi.package_id = tp.id) as itinerary
             FROM tour_packages tp
             LEFT JOIN package_pricing pp ON tp.id = pp.package_id
             WHERE tp.is_active = true
             ORDER BY tp.created_at DESC`
        );
        
        // Ensure all array fields are properly formatted
        const packages = result.rows.map(pkg => ({
            ...pkg,
            tags: pkg.tags || [],
            inclusions: pkg.inclusions || [],
            exclusions: pkg.exclusions || [],
            requirements: pkg.requirements || [],
            photos_urls: pkg.photos_urls || [],
            itinerary: pkg.itinerary || [],
            important_notes: pkg.important_notes || '',
            cancellation_policy: pkg.cancellation_policy || '',
            description: pkg.description || ''
        }));
        
        res.status(200).json(packages);
    } catch (err) {
        console.error('Get all packages error:', err);
        res.status(500).json({ error: "Failed to fetch packages", details: err.message });
    }
};

exports.getPackageById = async (req, res) => {
    try {
        // Removed hardcoded CORS headers to rely on global CORS middleware
        
        const { id } = req.params;
        const result = await db.query(
            `SELECT 
                tp.*, 
                pp.season, pp.price_per_person_international, pp.price_per_person_local, pp.price_per_person_diaspora,
                pp.child_discount_percentage, pp.infant_discount_percentage, pp.group_discount_percentage,
                (SELECT json_agg(pi.* ORDER BY pi.day_number) FROM package_itineraries pi WHERE pi.package_id = tp.id) as itinerary
             FROM tour_packages tp
             LEFT JOIN package_pricing pp ON tp.id = pp.package_id
             WHERE tp.id = $1`,
            [id]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: "Package not found" });
        
        // Ensure all array fields are properly formatted
        const pkg = result.rows[0];
        const formattedPackage = {
            ...pkg,
            tags: pkg.tags || [],
            inclusions: pkg.inclusions || [],
            exclusions: pkg.exclusions || [],
            requirements: pkg.requirements || [],
            photos_urls: pkg.photos_urls || [],
            itinerary: pkg.itinerary || [],
            important_notes: pkg.important_notes || '',
            cancellation_policy: pkg.cancellation_policy || '',
            description: pkg.description || ''
        };
        
        res.status(200).json(formattedPackage);
    } catch (err) {
        console.error('Get package by ID error:', err);
        res.status(500).json({ error: "Failed to fetch package", details: err.message });
    }
};

exports.updatePackage = async (req, res) => {
    const { id } = req.params;
    try {
        const { name, description, tour_type, difficulty, season_recommendation } = req.body;
        const duration_days = parseInt(req.body.duration_days);
        const duration_nights = parseInt(req.body.duration_nights);
        const min_group_size = parseInt(req.body.min_group_size);
        const max_group_size = parseInt(req.body.max_group_size);
        const is_active = req.body.is_active === 'true';
        
        const price_international = parseFloat(req.body.price_per_person_international) || 0;
        const price_local = parseFloat(req.body.price_per_person_local) || 0; 
        const price_diaspora = parseFloat(req.body.price_per_person_diaspora) || 0;
        const child_discount = parseFloat(req.body.child_discount_percentage) || 0;
        const infant_discount = parseFloat(req.body.infant_discount_percentage) || 0;
        const group_discount = parseFloat(req.body.group_discount_percentage) || 0;

        const inclusions = safeJSONParse(req.body.inclusions, []);
        const exclusions = safeJSONParse(req.body.exclusions, []);
        const requirements = safeJSONParse(req.body.requirements, []);
        const tags = safeJSONParse(req.body.tags, []);
        const itinerary = safeJSONParse(req.body.itinerary, []);
        let photos_urls = safeJSONParse(req.body.photos_urls, []);

        if (req.files && req.files.length > 0) {
            const uploadedFilePaths = req.files.map(file => `/uploads/${file.filename}`);
            photos_urls = [...photos_urls, ...uploadedFilePaths];
        }

        await db.query('BEGIN');

        // Update Main Table
        const pkgRes = await db.query(
            `UPDATE tour_packages 
             SET name = COALESCE($1, name), description = COALESCE($2, description), tour_type = COALESCE($3, tour_type),
                 difficulty = COALESCE($4, difficulty), season_recommendation = COALESCE($5, season_recommendation),
                 duration_days = COALESCE($6, duration_days), duration_nights = COALESCE($7, duration_nights),
                 min_group_size = COALESCE($8, min_group_size), max_group_size = COALESCE($9, max_group_size),
                 is_active = COALESCE($10, is_active), inclusions = $11, exclusions = $12, tags = $13, requirements = $14,
                 photos_urls = $15, updated_at = CURRENT_TIMESTAMP
             WHERE id = $16 RETURNING id`,
            [name, description, tour_type, difficulty, season_recommendation, duration_days, duration_nights, min_group_size, max_group_size, is_active, inclusions, exclusions, tags, requirements, photos_urls, id]
        );

        if (pkgRes.rows.length === 0) throw new Error("Package not found");

        // Upsert Pricing
        const pCheck = await db.query(`SELECT id FROM package_pricing WHERE package_id = $1`, [id]);
        if (pCheck.rows.length > 0) {
            await db.query(
                `UPDATE package_pricing 
                 SET price_per_person_international = $1, price_per_person_local = $2, price_per_person_diaspora = $3,
                     child_discount_percentage = $4, infant_discount_percentage = $5, group_discount_percentage = $6
                 WHERE package_id = $7`, 
                [price_international, price_local, price_diaspora, child_discount, infant_discount, group_discount, id]
            );
        } else {
            await db.query(
                `INSERT INTO package_pricing (package_id, season, price_per_person_international, price_per_person_local, price_per_person_diaspora, child_discount_percentage, infant_discount_percentage, group_discount_percentage) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, 
                [id, req.body.season || 'both', price_international, price_local, price_diaspora, child_discount, infant_discount, group_discount]
            );
        }

        // Recreate Itineraries
        await db.query(`DELETE FROM package_itineraries WHERE package_id = $1`, [id]);
        for (let day of itinerary) {
            await db.query(
                `INSERT INTO package_itineraries (package_id, day_number, title, description, accommodation_type, meal_plan, distance_km, travel_time_hours) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
                [id, day.day_number || 1, day.title || '', day.description || '', day.accommodation_type || '', day.meal_plan || '', parseFloat(day.distance_km) || 0, parseFloat(day.travel_time_hours) || 0]
            );
        }

        await db.query('COMMIT');
        res.status(200).json({ message: "Updated successfully" });
    } catch (err) {
        await db.query('ROLLBACK');
        res.status(500).json({ error: "Failed to update package", details: err.message });
    }
};

exports.deletePackage = async (req, res) => {
    try {
        const result = await db.query(`DELETE FROM tour_packages WHERE id = $1 RETURNING id`, [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: "Not found" });
        res.status(200).json({ message: "Package deleted successfully" });
    } catch (err) {
        res.status(500).json({ error: "Delete failed", details: err.message });
    }
};

exports.updatePackageStatus = async (req, res) => {
    try {
        await db.query(`UPDATE tour_packages SET is_active = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`, [req.body.is_active, req.params.id]);
        res.status(200).json({ message: "Status updated" });
    } catch (err) {
        res.status(500).json({ error: "Status update failed", details: err.message });
    }
};

// Mobile-specific package by ID endpoint
exports.getMobilePackageById = async (req, res) => {
    try {
        // Removed hardcoded CORS headers to rely on global CORS middleware
        
        const { id } = req.params;
        const result = await db.query(
            `SELECT 
                tp.id,
                tp.package_code,
                tp.name,
                tp.description,
                tp.tour_type,
                tp.difficulty,
                tp.duration_days,
                tp.duration_nights,
                tp.min_group_size,
                tp.max_group_size,
                tp.season_recommendation,
                tp.tags,
                tp.inclusions,
                tp.exclusions,
                tp.requirements,
                tp.important_notes,
                tp.cancellation_policy,
                tp.photos_urls,
                tp.is_customizable,
                tp.is_active,
                tp.created_at,
                pp.season, 
                pp.price_per_person_international, 
                pp.price_per_person_local, 
                pp.price_per_person_diaspora,
                pp.child_discount_percentage, 
                pp.infant_discount_percentage, 
                pp.group_discount_percentage,
                (SELECT json_agg(
                    json_build_object(
                        'day_number', pi.day_number,
                        'title', pi.title,
                        'description', pi.description,
                        'accommodation_type', pi.accommodation_type,
                        'meal_plan', pi.meal_plan,
                        'distance_km', pi.distance_km,
                        'travel_time_hours', pi.travel_time_hours
                    ) ORDER BY pi.day_number
                ) FROM package_itineraries pi WHERE pi.package_id = tp.id) as itinerary
             FROM tour_packages tp
             LEFT JOIN package_pricing pp ON tp.id = pp.package_id
             WHERE tp.id = $1 AND tp.is_active = true`,
            [id]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false,
                error: "Package not found or inactive" 
            });
        }

        const pkg = result.rows[0];
        
        // Format response for mobile app
        const formattedPackage = {
            id: pkg.id,
            package_code: pkg.package_code,
            name: pkg.name,
            description: pkg.description || '',
            tour_type: pkg.tour_type,
            difficulty: pkg.difficulty,
            duration_days: pkg.duration_days,
            duration_nights: pkg.duration_nights,
            min_group_size: pkg.min_group_size,
            max_group_size: pkg.max_group_size,
            season_recommendation: pkg.season_recommendation,
            tags: pkg.tags || [],
            inclusions: pkg.inclusions || [],
            exclusions: pkg.exclusions || [],
            requirements: pkg.requirements || [],
            important_notes: pkg.important_notes || '',
            cancellation_policy: pkg.cancellation_policy || '',
            photos_urls: pkg.photos_urls || [],
            is_customizable: pkg.is_customizable || false,
            is_active: pkg.is_active,
            created_at: pkg.created_at,
            pricing: {
                season: pkg.season,
                price_per_person_international: pkg.price_per_person_international || 0,
                price_per_person_local: pkg.price_per_person_local || 0,
                price_per_person_diaspora: pkg.price_per_person_diaspora || 0,
                child_discount_percentage: pkg.child_discount_percentage || 0,
                infant_discount_percentage: pkg.infant_discount_percentage || 0,
                group_discount_percentage: pkg.group_discount_percentage || 0
            },
            itinerary: pkg.itinerary || []
        };

        res.status(200).json({
            success: true,
            data: formattedPackage
        });
    } catch (err) {
        console.error('Mobile package by ID error:', err);
        res.status(500).json({ 
            success: false,
            error: "Failed to fetch package for mobile app", 
            details: err.message 
        });
    }
};

// Mobile-specific package endpoint with enhanced CORS and error handling
exports.getMobilePackages = async (req, res) => {
    try {
        // Removed hardcoded CORS headers to rely on global CORS middleware
        
        const result = await db.query(
            `SELECT 
                tp.id,
                tp.package_code,
                tp.name,
                tp.description,
                tp.tour_type,
                tp.difficulty,
                tp.duration_days,
                tp.duration_nights,
                tp.min_group_size,
                tp.max_group_size,
                tp.season_recommendation,
                tp.tags,
                tp.inclusions,
                tp.exclusions,
                tp.requirements,
                tp.important_notes,
                tp.cancellation_policy,
                tp.photos_urls,
                tp.is_customizable,
                tp.is_active,
                tp.created_at,
                pp.season, 
                pp.price_per_person_international, 
                pp.price_per_person_local, 
                pp.price_per_person_diaspora,
                pp.child_discount_percentage, 
                pp.infant_discount_percentage, 
                pp.group_discount_percentage,
                COALESCE(pp.price_per_person_international, 0) AS base_price,
                (SELECT json_agg(
                    json_build_object(
                        'day_number', pi.day_number,
                        'title', pi.title,
                        'description', pi.description,
                        'accommodation_type', pi.accommodation_type,
                        'meal_plan', pi.meal_plan,
                        'distance_km', pi.distance_km,
                        'travel_time_hours', pi.travel_time_hours
                    ) ORDER BY pi.day_number
                ) FROM package_itineraries pi WHERE pi.package_id = tp.id) as itinerary
             FROM tour_packages tp
             LEFT JOIN package_pricing pp ON tp.id = pp.package_id
             WHERE tp.is_active = true
             ORDER BY tp.created_at DESC`
        );

        // Format response for mobile app
        const packages = result.rows.map(pkg => ({
            id: pkg.id,
            package_code: pkg.package_code,
            name: pkg.name,
            description: pkg.description || '',
            tour_type: pkg.tour_type,
            difficulty: pkg.difficulty,
            duration_days: pkg.duration_days,
            duration_nights: pkg.duration_nights,
            min_group_size: pkg.min_group_size,
            max_group_size: pkg.max_group_size,
            season_recommendation: pkg.season_recommendation,
            tags: pkg.tags || [],
            inclusions: pkg.inclusions || [],
            exclusions: pkg.exclusions || [],
            requirements: pkg.requirements || [],
            important_notes: pkg.important_notes || '',
            cancellation_policy: pkg.cancellation_policy || '',
            photos_urls: pkg.photos_urls || [],
            is_customizable: pkg.is_customizable || false,
            is_active: pkg.is_active,
            created_at: pkg.created_at,
            pricing: {
                season: pkg.season,
                price_per_person_international: pkg.price_per_person_international || 0,
                price_per_person_local: pkg.price_per_person_local || 0,
                price_per_person_diaspora: pkg.price_per_person_diaspora || 0,
                child_discount_percentage: pkg.child_discount_percentage || 0,
                infant_discount_percentage: pkg.infant_discount_percentage || 0,
                group_discount_percentage: pkg.group_discount_percentage || 0,
                base_price: pkg.base_price || 0
            },
            itinerary: pkg.itinerary || []
        }));

        res.status(200).json({
            success: true,
            count: packages.length,
            data: packages
        });
    } catch (err) {
        console.error('Mobile packages error:', err);
        res.status(500).json({ 
            success: false,
            error: "Failed to fetch packages for mobile app", 
            details: err.message 
        });
    }
};