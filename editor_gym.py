import re

def read_file(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()

def write_file(p, s):
    with open(p, "w", encoding="utf-8") as f:
        f.write(s)

# ==============================================================================
# 1. PATCH worker.js: Open-Source Exercise DB Proxy (Anti-Sanction + Fast Cache)
# ==============================================================================
w = read_file("worker.js")

EXERCISE_ROUTES = r'''      // 4.6 Open-Source GitHub Exercise Dataset Proxy (free-exercise-db)
      if (path === "/api/exercise-media/resolve") {
        const u = new URL(request.url);
        const rawQ = String(u.searchParams.get("q") || "").toLowerCase().trim();
        const rawM = String(u.searchParams.get("m") || "").toLowerCase().trim();
        const text = (rawQ + " " + rawM).trim();

        const rules = [
          [["شنا الماسی", "diamond"], "Close-Grip_Push-Up_off_of_a_Dumbbell"],
          [["شنا پایک", "pike"], "Pike_Pushup"],
          [["شنا سوئدی", "شنا ", "pushup", "push-up", "push up"], "Pushups"],
          [["پرس سینه", "bench press", "chest press"], "Dumbbell_Bench_Press"],
          [["فلای", "قفسه سینه", "fly"], "Dumbbell_Flyes"],
          [["دیپ", "پشت‌بازو", "پشت بازو", "tricep", "dip"], "Bench_Dips"],
          [["جلوبازو", "جلو بازو", "bicep", "curl"], "Dumbbell_Bicep_Curl"],
          [["سرشانه", "نشر جانب", "shoulder", "lateral"], "Side_Lateral_Raise"],
          [["پرس سرشانه", "overhead"], "Dumbbell_Shoulder_Press"],
          [["زیربغل", "لت", "row", "بارفیکس", "pullup", "pull-up"], "One-Arm_Dumbbell_Row"],
          [["سوپرمن", "کشش معکوس", "superman"], "Superman"],
          [["اسکات", "squat"], "Bodyweight_Squat"],
          [["لانج", "لانگز", "lunge"], "Dumbbell_Lunges"],
          [["ددلیفت", "deadlift"], "Stiff-Legged_Dumbbell_Deadlift"],
          [["ساق پا", "calf"], "Standing_Calf_Raises"],
          [["پلانک", "plank"], "Plank"],
          [["کرانچ", "دراز و نشست", "شکم", "abs", "crunch"], "Crunches"],
          [["برپی", "burpee"], "Burpee"],
          [["پروانه", "jumping jack"], "Jumping_Jacks"],
          [["کوهنورد", "mountain"], "Mountain_Climbers"],
          [["باسن", "پل باسن", "glute", "bridge"], "Butt_Lift_Bridge"]
        ];

        let matchedFolder = "";
        for (const [keys, folder] of rules) {
          if (keys.some((k) => text.includes(k))) {
            matchedFolder = folder;
            break;
          }
        }

        if (!matchedFolder) {
          // Fallback search in cached GitHub dataset
          try {
            let dbRaw = await kv.get("cache:free_exercise_db_min_v1");
            let dbList = null;
            if (dbRaw) {
              dbList = JSON.parse(dbRaw);
            } else {
              const ghRes = await fetch("https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json");
              if (ghRes.ok) {
                const full = await ghRes.json();
                dbList = full.filter((x) => x.images && x.images.length >= 2).map((x) => ({
                  n: String(x.name || "").toLowerCase(),
                  i0: x.images[0],
                  i1: x.images[1]
                }));
                await kv.put("cache:free_exercise_db_min_v1", JSON.stringify(dbList), { expirationTtl: 604800 });
              }
            }
            if (Array.isArray(dbList)) {
              const words = rawQ.split(/\s+/).filter((w) => w.length > 2);
              const hit = dbList.find((item) => words.some((wd) => item.n.includes(wd)));
              if (hit) {
                return jsonResponse({
                  success: true,
                  frames: [
                    "/api/exercise-media/img?p=" + encodeURIComponent(hit.i0),
                    "/api/exercise-media/img?p=" + encodeURIComponent(hit.i1)
                  ]
                });
              }
            }
          } catch (_) {}
          matchedFolder = "Pushups";
        }

        return jsonResponse({
          success: true,
          frames: [
            "/api/exercise-media/img?p=" + encodeURIComponent(matchedFolder + "/0.jpg"),
            "/api/exercise-media/img?p=" + encodeURIComponent(matchedFolder + "/1.jpg")
          ]
        });
      }

      if (path === "/api/exercise-media/img") {
        const u = new URL(request.url);
        const p = String(u.searchParams.get("p") || "").replace(/\.\./g, "").trim();
        if (!p || !p.endsWith(".jpg")) {
          return new Response("Invalid path", { status: 400 });
        }
        const ghUrl = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/" + p;
        const imgRes = await fetch(ghUrl, { cf: { cacheTtl: 86400, cacheEverything: true } });
        if (!imgRes.ok) {
          return new Response("Not found", { status: 404 });
        }
        return new Response(imgRes.body, {
          status: 200,
          headers: {
            "Content-Type": "image/jpeg",
            "Cache-Control": "public, max-age=86400",
            "Access-Control-Allow-Origin": "*"
          }
        });
      }

      // 5. User Profile, 3-Stage Lock Check & Cloud Sync'''

w_anchor = '      // 5. User Profile, 3-Stage Lock Check & Cloud Sync'
if "/api/exercise-media/resolve" not in w and w_anchor in w:
    w = w.replace(w_anchor, EXERCISE_ROUTES, 1)
    write_file("worker.js", w)
    print("✅ Patched worker.js: Added GitHub Exercise Dataset proxy routes")
else:
    print("ℹ️ worker.js exercise proxy already present or anchor missing")

# ==============================================================================
# 2. PATCH lib/main.dart: BmExerciseDemoBox + Optional Offline Download + Auto Cleanup
# ==============================================================================
d = read_file("lib/main.dart")

if "import 'dart:typed_data';" not in d:
    d = "import 'dart:typed_data';\n" + d

WIDGET_CODE = r'''
class BmExerciseOfflineManager {
  static bool _checkedTodayCleanup = false;
  static bool showYesterdayCleanedBanner = false;

  static String _iranTodayStr() {
    final iran = DateTime.now().toUtc().add(const Duration(hours: 3, minutes: 30));
    final y = iran.year.toString().padLeft(4, '0');
    final m = iran.month.toString().padLeft(2, '0');
    final d = iran.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<void> checkAndCleanupYesterday() async {
    if (_checkedTodayCleanup) return;
    _checkedTodayCleanup = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString('bm_offline_ex_date_v1') ?? '';
      final today = _iranTodayStr();
      if (savedDate.isNotEmpty && savedDate != today) {
        await prefs.remove('bm_offline_ex_cache_v1');
        await prefs.remove('bm_offline_ex_date_v1');
        showYesterdayCleanedBanner = true;
      }
    } catch (_) {}
  }

  static Future<List<Uint8List>?> getCachedFrames(String exerciseName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('bm_offline_ex_cache_v1');
      if (raw == null || raw.isEmpty) return null;
      final Map<String, dynamic> map = jsonDecode(raw);
      final entry = map[exerciseName];
      if (entry is List && entry.length >= 2) {
        return [
          base64Decode(entry[0].toString()),
          base64Decode(entry[1].toString()),
        ];
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> isTodayDownloaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('bm_offline_ex_date_v1') ?? '') == _iranTodayStr();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> downloadAllForToday(List<String> names) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> cache = {};
      for (final name in names) {
        final rUri = Uri.parse(
          '${AppConfig.serverBaseUrl}/api/exercise-media/resolve?q=${Uri.encodeComponent(name)}',
        );
        final rRes = await http.get(rUri).timeout(const Duration(seconds: 10));
        if (rRes.statusCode == 200) {
          final data = jsonDecode(utf8.decode(rRes.bodyBytes));
          final frames = data['frames'];
          if (frames is List && frames.length >= 2) {
            final f0 = await http.get(Uri.parse('${AppConfig.serverBaseUrl}${frames[0]}')).timeout(const Duration(seconds: 10));
            final f1 = await http.get(Uri.parse('${AppConfig.serverBaseUrl}${frames[1]}')).timeout(const Duration(seconds: 10));
            if (f0.statusCode == 200 && f1.statusCode == 200) {
              cache[name] = [base64Encode(f0.bodyBytes), base64Encode(f1.bodyBytes)];
            }
          }
        }
      }
      if (cache.isNotEmpty) {
        await prefs.setString('bm_offline_ex_cache_v1', jsonEncode(cache));
        await prefs.setString('bm_offline_ex_date_v1', _iranTodayStr());
        return true;
      }
    } catch (_) {}
    return false;
  }
}

class BmExerciseDemoBox extends StatefulWidget {
  final String exerciseName;
  final String muscleGroup;
  final List<String> allTodayNames;

  const BmExerciseDemoBox({
    super.key,
    required this.exerciseName,
    required this.muscleGroup,
    required this.allTodayNames,
  });

  @override
  State<BmExerciseDemoBox> createState() => _BmExerciseDemoBoxState();
}

class _BmExerciseDemoBoxState extends State<BmExerciseDemoBox> {
  List<Uint8List>? _offlineBytes;
  List<String>? _onlineUrls;
  int _frameIdx = 0;
  Timer? _animTimer;
  bool _loading = true;
  bool _downloadingAll = false;
  bool _todaySaved = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
    _animTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted) setState(() => _frameIdx = (_frameIdx == 0) ? 1 : 0);
    });
  }

  @override
  void didUpdateWidget(covariant BmExerciseDemoBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName) {
      _initMedia();
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  Future<void> _initMedia() async {
    if (mounted) setState(() => _loading = true);
    await BmExerciseOfflineManager.checkAndCleanupYesterday();
    if (BmExerciseOfflineManager.showYesterdayCleanedBanner && mounted) {
      BmExerciseOfflineManager.showYesterdayCleanedBanner = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 6),
              content: Text(
                'رفیق نگران نباش حافظه گوشیت به این زودی پر نمیشه 😅 دیتایی که دیروز دانلود کردی پاک شده و الان میتونی دیتای جدید دانلود کنی 😉',
              ),
            ),
          );
        }
      });
    }

    final savedToday = await BmExerciseOfflineManager.isTodayDownloaded();
    final cached = await BmExerciseOfflineManager.getCachedFrames(widget.exerciseName);
    if (cached != null && cached.length >= 2) {
      if (mounted) {
        setState(() {
          _offlineBytes = cached;
          _todaySaved = savedToday;
          _loading = false;
        });
      }
      return;
    }

    try {
      final uri = Uri.parse(
        '${AppConfig.serverBaseUrl}/api/exercise-media/resolve?q=${Uri.encodeComponent(widget.exerciseName)}&m=${Uri.encodeComponent(widget.muscleGroup)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final frames = data['frames'];
        if (frames is List && frames.length >= 2 && mounted) {
          setState(() {
            _offlineBytes = null;
            _onlineUrls = [
              '${AppConfig.serverBaseUrl}${frames[0]}',
              '${AppConfig.serverBaseUrl}${frames[1]}',
            ];
            _todaySaved = savedToday;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _todaySaved = savedToday;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 175,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BMColors.neonCyan.withOpacity(0.35)),
          ),
          clipBehavior: Clip.antiAlias,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : (_offlineBytes != null && _offlineBytes!.length >= 2)
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _offlineBytes![_frameIdx],
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'آفلاین ⚡',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: BMColors.neonGreen),
                            ),
                          ),
                        ),
                      ],
                    )
                  : (_onlineUrls != null && _onlineUrls!.length >= 2)
                      ? Image.network(
                          _onlineUrls![_frameIdx],
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('🎬 پیش‌نمایش حرکت در حال بارگذاری...', style: TextStyle(fontSize: 12)),
                          ),
                        )
                      : const Center(
                          child: Text('🏋️‍♂️ راهنمای تصویری حرکت', style: TextStyle(fontSize: 12)),
                        ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _todaySaved ? BMColors.neonGreen : BMColors.neonCyan.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: (_downloadingAll || _todaySaved)
                ? null
                : () async {
                    setState(() => _downloadingAll = true);
                    final ok = await BmExerciseOfflineManager.downloadAllForToday(widget.allTodayNames);
                    if (mounted) {
                      setState(() {
                        _downloadingAll = false;
                        _todaySaved = ok;
                      });
                      if (ok) {
                        _initMedia();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('همه‌ی حرکات امروز برای حالت آفلاین دانلود شد! ⚡📥')),
                        );
                      }
                    }
                  },
            icon: _downloadingAll
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_todaySaved ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined, size: 18),
            label: Text(
              _downloadingAll
                  ? 'در حال دانلود حرکات امروز...'
                  : (_todaySaved ? 'حرکات امروز آفلاین ذخیره شد ✅ (فردا خودکار پاک می‌شه)' : 'دانلود حرکات امروز برای حالت آفلاین (اختیاری) ⬇️'),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
'''

if "class BmExerciseDemoBox" not in d:
    m = re.search(r'\n(void main\(|class )', d)
    if m:
        idx = m.start()
        d = d[:idx] + "\n" + WIDGET_CODE + d[idx:]
        print("✅ Patched lib/main.dart: Added BmExerciseDemoBox & Offline Manager")

gym_anchor = """              Text(
                '🎯 عضله هدف: ${bmExStr(safeIdx, 'muscle', activeStep.muscleGroup)} • تکرار: ${activeStep.repsOrDuration}',
                style: TextStyle(fontSize: 12.5, color: bmTextSubColor),
              ),
              const SizedBox(height: 12),"""

gym_insert = gym_anchor + """
              BmExerciseDemoBox(
                exerciseName: bmExStr(safeIdx, 'title', activeStep.name),
                muscleGroup: bmExStr(safeIdx, 'muscle', activeStep.muscleGroup),
                allTodayNames: List.generate(steps.length, (i) => bmExStr(i, 'title', steps[i].name)),
              ),
              const SizedBox(height: 12),"""

if "BmExerciseDemoBox(" not in d and gym_anchor in d:
    d = d.replace(gym_anchor, gym_insert, 1)
    print("✅ Patched lib/main.dart: Inserted BmExerciseDemoBox into Live Gym card")
else:
    print("ℹ️ BmExerciseDemoBox already inserted or anchor mismatch")

write_file("lib/main.dart", d)
print("\n🎉 GYM DATASET PATCH COMPLETE!")
