import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export const login = async (req, res) => {
    try {

        const { uid, email, name, photoURL } = req.body;

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





