export const getCoinDistribution = async (req: Request, res: Response) => {
  try {
    const { startDate, endDate } = req.query;
    
    let dateFilter: any = {};
    if (startDate && endDate) {
      dateFilter = {
        createdAt: {
          gte: new Date(startDate as string),
          lte: new Date(endDate as string)
        }
      };
    }

    const transactions = await prisma.transaction.findMany({
      where: {
        type: { in: ['earning', 'bonus'] },
        status: 'success',
        ...dateFilter
      },
      select: {
        amount: true,
        description: true,
        createdAt: true,
        userId: true,
        user: { select: { username: true, phoneNumber: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: transactions });
  } catch (error) {
    console.error('Error fetching coin distribution:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getUpcomingWithdrawals = async (req: Request, res: Response) => {
  try {
    const users5k = await prisma.user.findMany({
      where: { balance: { gte: 3500, lt: 12000 }, isBlocked: false },
      select: { id: true, username: true, phoneNumber: true, balance: true, totalEarned: true }
    });
    
    const users15k = await prisma.user.findMany({
      where: { balance: { gte: 12000, lt: 48000 }, isBlocked: false },
      select: { id: true, username: true, phoneNumber: true, balance: true, totalEarned: true }
    });
    
    const users100k = await prisma.user.findMany({
      where: { balance: { gte: 48000 }, isBlocked: false },
      select: { id: true, username: true, phoneNumber: true, balance: true, totalEarned: true }
    });

    res.json({
      success: true,
      data: {
        category5k: users5k,
        category15k: users15k,
        category100k: users100k
      }
    });
  } catch (error) {
    console.error('Error fetching upcoming withdrawals:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
