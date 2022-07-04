<div align="center">
  
# sample codes to determine the policy ID

</div>


## PERL

```perl
#!/usr/bin/perl

use Digest::MD5 qw(md5 md5_hex md5_base64);
my $pname = "/Common/p1";
my $md5 = md5_base64($pname);
print $md5 . "\n";
```

```console
# perl policyId.pl
2qRI23V2PScRAZJGYeWNGg
```

## PYTHON

```python
from hashlib import md5
import base64

pname = "/Common/p1"
print base64.b64encode(md5(pname.encode()).digest()).replace("=", "")
```

```console
# python policyID.py
2qRI23V2PScRAZJGYeWNGg
```

## GOLANG

```golang
package main

import (
	"fmt"
	"strings"
	"crypto/md5"
	b64 "encoding/base64"
)

func Hasher(policyName string) string {
	hasher := md5.New()
	hasher.Write([]byte(policyName))
	encodedString := b64.StdEncoding.EncodeToString(hasher.Sum(nil))

	return strings.TrimRight(encodedString, "=")
}

func main() {
	var partition string
	var policyName string
	fmt.Println("Partition Name (example: Common)")
	fmt.Scanln(&partition)
        fmt.Println("Policy Name (example: myPolicy)")
        fmt.Scanln(&policyName)

	fullName := "/" + partition + "/" + policyName
	policyId := Hasher(fullName)
	fmt.Println("Policy Id: ", policyId)
}
```

```console
# go build
# ./policyID
Partition Name (example: Common)
Common
Policy Name (example: myPolicy)
p1
Policy Id:  2qRI23V2PScRAZJGYeWNGg
```
