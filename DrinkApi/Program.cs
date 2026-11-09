using Microsoft.EntityFrameworkCore;
using DrinkApi.Data;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.UseUrls("http://0.0.0.0:5000");
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    // Cho phép nhập mã nhân viên trong nút Authorize của Swagger để thử API quản trị.
    c.AddSecurityDefinition("AdminKey", new Microsoft.OpenApi.OpenApiSecurityScheme
    {
        Name = DrinkApi.Auth.AdminKeyAttribute.HeaderName,
        In = Microsoft.OpenApi.ParameterLocation.Header,
        Type = Microsoft.OpenApi.SecuritySchemeType.ApiKey,
        Description = "Mã nhân viên (Admin:ApiKey) cho các API quản trị."
    });

    // Chỉ đánh dấu yêu cầu bảo mật cho các action có [AdminKey].
    c.OperationFilter<DrinkApi.Auth.AdminKeyOperationFilter>();
});

builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// CORS chỉ có ý nghĩa với client web; app mobile không gửi header Origin.
// Danh sách origin cho phép nằm trong appsettings.json (Cors:AllowedOrigins),
// thêm origin của client web vào đó khi cần.
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? new[] { "http://localhost:8080" };

builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.WithOrigins(allowedOrigins).AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();

// Ảnh món mẫu nằm trong wwwroot/images, phục vụ tại /images/...
app.UseStaticFiles();

app.MapControllers();
app.Run();