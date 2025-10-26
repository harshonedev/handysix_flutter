import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

export const getUserByUid = async (userId) => {
    try {
        const user = await prisma.user.findUnique({
            where: { uid: userId },
            select: {
                id: true,
                uid: true,
                name: true,
                profilePicture: true,
                email: true,
            },
        });
        return user;
    } catch (error) {
        console.error('Error fetching user by ID:', error);
        throw error;
    }
};