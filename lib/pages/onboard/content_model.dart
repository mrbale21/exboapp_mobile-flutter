class UnboardingContent {
  String image;
  String title;
  String description;
  UnboardingContent(
      {required this.description, required this.image, required this.title});
}

List<UnboardingContent> contents = [
  UnboardingContent(
      description:
          'Explore Bogor (EXBO) App, yang mempunyai fitur rekomendasi wisata di Bogor untuk siapa saja yang merasa bingung dan ingin berlibur di Bogor',
      image: 'assets/images/onboard_tugu.png',
      title: 'ExboApp'),
  UnboardingContent(
      description:
          'Dapatkan rekomendasi tempat wisata hanya dengan satu klik. \nBerikan rating ke beberapa tempat wisata yang anda sukai dan dapatkan rekomendasi berdasarkan kemiripan rating dari pengguna lain.',
      image: 'assets/images/onboard_recomendation.png',
      title: 'Fitur Rekomendasi'),
  UnboardingContent(
      description:
          'Gunakan ExboApp, dengan berbagai fitur rekomendasi serta pilihan tempat wisata yang banyak dan menarik, maka rencana perjalanan Anda di Bogor akan terasa seru dan menyenangkan. Tunggu apalagi, gaskeun dan coba sekarang juga.',
      image: 'assets/images/onboard_travel.png',
      title: 'Explore Sekarang!'),
];
