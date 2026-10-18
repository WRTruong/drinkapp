using Microsoft.EntityFrameworkCore;
using DrinkApi.Models;

namespace DrinkApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
    public DbSet<Drink> Drinks => Set<Drink>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<Drink>().ToTable("Drinks");
        b.Entity<Order>().ToTable("Orders");
        b.Entity<OrderItem>().ToTable("OrderItems");
        b.Entity<Order>().HasIndex(o => o.OrderCode).IsUnique();
    }
}