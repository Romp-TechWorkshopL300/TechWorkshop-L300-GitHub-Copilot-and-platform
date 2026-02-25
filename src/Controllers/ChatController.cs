using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ContentSafetyService _contentSafety;
    private readonly AIChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(ContentSafetyService contentSafety, AIChatService chatService, ILogger<ChatController> logger)
    {
        _contentSafety = contentSafety;
        _chatService = chatService;
        _logger = logger;
    }

    public IActionResult Index()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> Send([FromBody] ChatRequest request)
    {
        if (string.IsNullOrWhiteSpace(request?.Message))
            return BadRequest(new ChatResponse { Reply = "Please enter a message." });

        // Content Safety gate
        var safetyResult = await _contentSafety.EvaluateAsync(request.Message);
        if (!safetyResult.IsSafe)
        {
            _logger.LogWarning("Message blocked by Content Safety: {Reason}", safetyResult.Reason);
            return Ok(new ChatResponse
            {
                Reply = "Sorry, I'm unable to process that request. Please rephrase your message and try again.",
                Blocked = true
            });
        }

        // Safe — forward to model
        var reply = await _chatService.GetResponseAsync(request.Message);
        return Ok(new ChatResponse { Reply = reply });
    }
}

public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
}

public class ChatResponse
{
    public string Reply { get; set; } = string.Empty;
    public bool Blocked { get; set; }
}
