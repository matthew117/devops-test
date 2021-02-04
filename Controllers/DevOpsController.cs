using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace TestWebApi.Controllers
{
    [ApiController]
    [Route("api/v1/devops")]
    public class DevOpsController : ControllerBase
    {
        [HttpGet("build/{number}")]
        public IActionResult GetBuildNumber(string number)
        {
            return Ok($"Secret is : {ServerData.Secret}. Build number is : {number}");
        }
    }
}
