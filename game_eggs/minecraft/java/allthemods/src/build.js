import * as fs from "fs";
import * as path from "path";
import * as url from "url";
import * as readline "readline";

const __dirname = url.fileURLToPath(new URL(".", import.meta.url));

const buildFile = path.join(__dirname, "install-script.sh");

const buildDir = path.join(__dirname, "build");

async function readBuildFile() {
  const fileStream = fs.createReadStream(buildFile);

  const rl = readline.createInterface({
    input: fileStream,
    crlfDelay: Infinity,
  });
  // Note: we use the crlfDelay option to recognize all instances of CR LF
  // ('\r\n') in input.txt as a single line break.

  for await (const line of rl) {
    // Each line in input.txt will be successively available here as `line`.
    if (/# include: /i.test(line)) {
      const testForFiles = line.matchAll(/# include: .*[\\/](.*)\.(.*)/i);

      for (const match of testForFiles) {
        console.log(match);
        if (fs.existsSync(match)) {
          console.log("true");
        }
      }
    }
  }
}

(async function () {
  await readBuildFile();
})();