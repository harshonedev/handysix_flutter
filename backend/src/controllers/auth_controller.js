import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const login = async (req, res) => {
    try {

        const { uid, email, name, photoURL } = req.body;

        // validate uid
        if (!uid) {
            return res.status(400).json({
                success: false,
                message: 'Firebase UID is required'
            });
        }

        // Fetch user by Firebase ID from the database
        const user = await prisma.user.findUnique({
            where: {
                uid: uid,
            },
        });

        // If user is not found, create a new user
        if (!user) {
            const newUser = await prisma.user.create({
                data: {
                    uid: uid,
                    name: name || 'Guest',
                    email: email || null,
                    profilePicture: photoURL || null,
                },
            });

            return res.status(201).json({
                success: true,
                message: 'User created successfully',
                user: newUser,
            });
        }

        // Respond with user data
        return res.status(200).json({
            success: true,
            message: 'User logged in successfully',
            user: user,
        });
    } catch (error) {
        console.error('Error fetching user by Firebase ID:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message,
        });
    }
}

export const getUserById = async (req, res) => {
    const { id } = req.params;

    try {
        const user = await prisma.user.findUnique({
            where: {
                id: id,
            },
            include: {
                stats: true, // Include related stats if needed
            },
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found',
            });
        }

        return res.status(200).json({
            success: true,
            user: user,
        });
    } catch (error) {
        console.error('Error fetching user by ID:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message,
        });
    }
}





