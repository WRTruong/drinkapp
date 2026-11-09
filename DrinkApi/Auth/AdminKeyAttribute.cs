using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace DrinkApi.Auth;

/// <summary>
/// Chặn các API quản trị: yêu cầu header X-Admin-Key khớp với Admin:ApiKey
/// trong cấu hình (appsettings hoặc biến môi trường Admin__ApiKey).
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class AdminKeyAttribute : Attribute, IAsyncActionFilter
{
    public const string HeaderName = "X-Admin-Key";

    public async Task OnActionExecutionAsync(
        ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var config = context.HttpContext.RequestServices
            .GetRequiredService<IConfiguration>();
        var expected = config["Admin:ApiKey"];

        if (string.IsNullOrWhiteSpace(expected))
        {
            context.Result = new ObjectResult(new
            {
                error = "Server chưa cấu hình mã nhân viên (Admin:ApiKey)."
            })
            {
                StatusCode = StatusCodes.Status500InternalServerError
            };
            return;
        }

        var provided = context.HttpContext.Request.Headers[HeaderName].ToString();
        if (!string.Equals(provided, expected, StringComparison.Ordinal))
        {
            context.Result = new ObjectResult(new { error = "Mã nhân viên không đúng." })
            {
                StatusCode = StatusCodes.Status401Unauthorized
            };
            return;
        }

        await next();
    }
}
