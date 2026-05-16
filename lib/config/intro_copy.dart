import 'dart:math';

/// Texty úvodnej obrazovky — pri každom spustení náhodný výber.
class IntroCopy {
  IntroCopy._();

  static final _rand = Random();

  static const taglines = <String>[
    'Opíš svoju náladu prirodzene — AI nájde filmy s náladovou paletou a dôvodmi.',
    'Žiadne nudné žánre — len tvoja chvíľa a filmy, ktoré k nej sedia.',
    'Čo máš dnes na duši? Napíš to a nechaj CineMatch vybrať tón večera.',
    'Od únavy po eufóriu — každá nálada má svoj soundtrack aj svoj film.',
    'Krátky text, silný výber: trailer, paleta farieb, tagy a dôvody prečo práve toto.',
    'Netflix sa pýta žáner. My sa pýtame, ako sa dnes cítiš.',
    'Napiš situáciu ako kamarátovi — AI ju preloží na 3–5 filmových zážitkov.',
    'Jesenná mlha, letná nostalgía, nedeľňajší chill — všetko sa dá opísať slovami.',
    'Tvoj večer, tvoja pravidlá: mysteriózne ale nie strašidelné? Napíš to sem.',
    'Film nie je filter. Je to nálada — a tú ty poznáš najlepšie.',
  ];

  static const hints = <String>[
    'Som po ťažkom týždni, chcem niečo mysteriózne, nie horor, jesenná atmosféra…',
    'Chcem komédiu, ale nie hlúpu — skôr suchý humor a neočakávané zápletky.',
    'Náladu mám ako po rozchode, ideálne niečo krásne a trochu smutné…',
    'Dnes len ležím na gauči — niečo ľahké, krátke, aby ma to „neslo“. ',
    'Chcel by som sci-fi, kde sú ľudské postavy dôležitejšie ako laserové zbrane.',
    'Mám chuť na napätie ako v thrilleroch z 90. rokov, neočakávaný zvrat.',
    'Niečo vizuálne silné, málo dialógov, veľa atmosféry — skôr art ako blockbuster.',
    'Večer s priateľkou — romantika OK, ale nie sladká rozprávka.',
    'Som unavený, nechcem čítať titulky — angličtina ale slovenčina dabing, záleží…',
    'Chcem film, ktorý mi zmení náladu z „meh“ na „wow“ za dve hodiny.',
  ];

  static String randomTagline() => taglines[_rand.nextInt(taglines.length)];

  static String randomHint() => hints[_rand.nextInt(hints.length)];
}
