using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace TestWebApi
{
    public class RandomConfig
    {
        public Secret Secret { get; set; }
    }

    public class Secret
    {
        public string Value { get; set; }
    }
}
