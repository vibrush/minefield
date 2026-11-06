# GAME DESIGN DOCUMENT (GDD)
## MINEFIELD
**Versi:** 1.1  
**Genre:** Competitive Multiplayer / Strategy / Puzzle  
**Platform:** PC  
**Mode:** Local Multiplayer (2 Players)  
**Input:** Satu keyboard  
**Perspektif:** Top-Down 2D

---

## 1. Game Overview

### 1.1 Konsep Permainan

Minefield adalah game kompetitif untuk dua pemain yang bertanding dalam satu arena penuh ranjau. Kedua pemain berperan sebagai personel yang ditugaskan mengamankan sebuah kawasan perkotaan terbengkalai yang dipenuhi asap tebal dan ranjau tersembunyi.

Pemain harus menjelajahi arena, mengumpulkan informasi dari kotak-kotak di sekitarnya, dan menandai lokasi ranjau menggunakan bendera. Pemain harus berhati-hati karena setiap kesalahan dapat mengurangi jumlah nyawa.

Kedua pemain bermain secara bersamaan dalam satu arena, tetapi memiliki penglihatan dan catatan eksplorasi masing-masing. Informasi yang ditemukan oleh satu pemain tidak otomatis diketahui oleh pemain lainnya.

### 1.2 Core Gameplay

1. Menjelajahi arena berbentuk grid.
2. Mengungkap kotak untuk mendapatkan informasi.
3. Menggunakan angka pada kotak untuk memperkirakan lokasi ranjau.
4. Menandai kotak yang dicurigai mengandung ranjau.
5. Menghindari ranjau agar tidak kehilangan nyawa.
6. Mengumpulkan poin sebanyak mungkin dengan menandai ranjau secara benar.

### 1.3 Game Objective

Pemain dengan jumlah bendera benar terbanyak ketika waktu permainan berakhir menjadi pemenang.

---

## 2. Game Configuration

### 2.1 Difficulty Settings

| Difficulty | Ukuran Arena | Total Tile | Jumlah Bom | Bendera per Pemain | Durasi |
|---|---:|---:|---:|---:|---:|
| Easy | 10 × 10 | 100 | 12 | 12 | 3 menit |
| Medium | 16 × 16 | 256 | 40 | 40 | 5 menit |
| Hard | 20 × 24 | 480 | 90 | 90 | 8 menit |

Setiap pemain memiliki jumlah bendera yang sama dengan total bom di arena.

Contoh: Jika arena memiliki 20 bom, masing-masing pemain mendapatkan 20 bendera.

Nilai konfigurasi di atas merupakan nilai awal yang dapat disesuaikan berdasarkan hasil playtesting.

### 2.2 Initial Player Configuration

- Jumlah pemain: 2.
- Nyawa awal: 3.
- Kedua pemain memulai permainan dari sisi arena yang berlawanan.
- Posisi awal pemain harus berada pada tile aman.
- Posisi bom ditentukan secara acak ketika pertandingan dimulai dan tidak berubah selama pertandingan berlangsung.

---

## 3. Game Mode and Arena

### 3.1 Game Mode

Game menggunakan mode **Local Versus Multiplayer**.

Kedua pemain bermain secara bersamaan pada satu perangkat dan satu keyboard. Tampilan permainan menggunakan split-screen sehingga setiap pemain memiliki area pandang masing-masing.

### 3.2 Arena Design

Arena menggunakan sistem grid dua dimensi. Setiap kotak disebut sebagai tile.

Setiap tile dapat memiliki kondisi berikut:

- Belum pernah dijelajahi.
- Tile aman.
- Tile mengandung bom.
- Tile memiliki bendera.
- Tile sedang berada dalam jangkauan penglihatan pemain.

### 3.3 Split-Screen

Tampilan permainan dibagi menjadi dua bagian:

- Bagian kiri: Player 1.
- Bagian kanan: Player 2.

Kedua pemain berada pada arena yang sama, tetapi informasi penglihatan dan eksplorasi disimpan secara terpisah.

---

## 4. Player Controls

### 4.1 Player 1

| Aksi | Tombol |
|---|---|
| Menghadap atas | W |
| Menghadap kiri | A |
| Menghadap bawah | S |
| Menghadap kanan | D |
| Reveal tile | Q |
| Pasang/Hapus bendera | E |

### 4.2 Player 2

| Aksi | Tombol |
|---|---|
| Menghadap atas | ↑ |
| Menghadap kiri | ← |
| Menghadap bawah | ↓ |
| Menghadap kanan | → |
| Reveal tile | . |
| Pasang/Hapus bendera | / |

### 4.3 Movement System

Pergerakan pemain menggunakan sistem grid-based movement.

Aturan pergerakan:

1. Menekan tombol arah satu kali hanya mengubah arah hadap pemain.
2. Menahan tombol arah membuat pemain bergerak ke arah tersebut.
3. Pemain hanya dapat bergerak mengikuti jalur grid.
4. Kecepatan awal yang direkomendasikan adalah 2 tile per detik.
5. Kedua pemain dapat bergerak secara bersamaan.

Kecepatan pergerakan dapat diuji pada 2, 3, dan 4 tile per detik untuk menentukan tingkat permainan yang paling sesuai.

### 4.4 Facing Direction

Pemain hanya dapat berinteraksi dengan tile yang berada tepat di depan arah hadapnya.

Tile target akan diberikan outline atau highlight agar pemain mengetahui tile yang sedang dituju.

---

## 5. Tile Interaction System

### 5.1 Reveal Tile

Pemain dapat membuka tile yang berada tepat di depannya menggunakan tombol reveal.

Ketentuan:

- Tile aman akan menampilkan angka atau kondisi kosong.
- Tile yang mengandung bom akan mengurangi satu nyawa pemain.
- Tile yang sudah memiliki bendera tidak dapat di-reveal sebelum benderanya dihapus.
- Pemain tidak dapat membuka tile yang berada di luar jangkauan interaksinya.

### 5.2 Flag System

Pemain dapat memasang atau menghapus bendera pada tile yang berada tepat di depannya.

Ketentuan:

1. Bendera dapat dipasang pada tile yang belum pernah di-reveal.
2. Satu tile hanya dapat memiliki satu bendera.
3. Tile yang sudah memiliki bendera tidak dapat diberi bendera tambahan.
4. Bendera yang salah tetap dapat dipasang.
5. Bendera yang salah dapat menghalangi lawan untuk memasang bendera pada tile tersebut.
6. Bendera dapat dihapus menggunakan tombol interaksi yang sama.

### 5.3 Flag Inventory

Setiap pemain memiliki jumlah bendera sesuai jumlah bom dalam arena.

Bendera yang telah digunakan mengurangi jumlah bendera yang tersedia.

Ketika pemain kehilangan seluruh nyawa dan tereliminasi, seluruh bendera milik pemain tersebut akan dihapus.

---

## 6. Minesweeper System

### 6.1 Bomb Generation

Bom ditempatkan secara acak ketika pertandingan dimulai.

Ketentuan:

- Jumlah bom mengikuti tingkat kesulitan.
- Posisi bom tetap selama pertandingan berlangsung.
- Posisi awal pemain harus berada pada tile aman.

### 6.2 Number System

Setiap tile aman yang di-reveal akan menampilkan angka berdasarkan jumlah bom pada delapan tile di sekelilingnya.

Delapan tile tersebut meliputi:

- Atas.
- Bawah.
- Kiri.
- Kanan.
- Kiri atas.
- Kanan atas.
- Kiri bawah.
- Kanan bawah.

Contoh:

Jika sebuah tile menampilkan angka 3, berarti terdapat tiga bom pada delapan tile di sekelilingnya.

### 6.3 Bomb Interaction

Bom dapat menyebabkan pemain kehilangan satu nyawa melalui dua cara:

1. Pemain melakukan reveal pada tile yang mengandung bom.
2. Pemain menginjak tile yang mengandung bom.

Tile bom yang sudah di-reveal tidak akan terus terlihat setelah keluar dari jangkauan penglihatan pemain. Tile tersebut akan kembali tertutup asap.

Jika pemain kembali menginjak tile tersebut, bom tetap dapat meledak dan mengurangi nyawa.

---

## 7. Fog of War and Vision System

### 7.1 Vision Range

Setiap pemain memiliki jangkauan penglihatan berbentuk persegi 3 × 3 dengan posisi pemain sebagai pusatnya.

Artinya, pemain dapat melihat:

- Tile tempat pemain berdiri.
- Delapan tile yang mengelilinginya.

### 7.2 Separate Vision

Setiap pemain memiliki sistem Fog of War yang terpisah.

Informasi yang ditemukan Player 1 tidak otomatis terlihat oleh Player 2, begitu juga sebaliknya.

Satu tile dapat terlihat oleh Player 1 tetapi masih tertutup oleh asap bagi Player 2.

### 7.3 Exploration Memory

Sistem eksplorasi memiliki tiga kondisi:

| Status | Deskripsi |
|---|---|
| Unexplored | Tile belum pernah di-reveal oleh pemain. |
| Explored but Hidden | Tile pernah di-reveal, tetapi sekarang berada di luar jangkauan penglihatan. |
| Visible | Tile sedang berada dalam jangkauan penglihatan pemain. |

### 7.4 Information Persistence

Informasi tile aman yang sudah ditemukan akan tersimpan dalam memori eksplorasi pemain.

Ketika tile aman keluar dari jangkauan penglihatan:

- Tile kembali tertutup asap.
- Informasi angka yang pernah ditemukan tetap tersimpan.
- Ketika pemain kembali mendekati tile tersebut, informasi angka dapat ditampilkan kembali.

Khusus tile bom:

- Informasi bahwa tile mengandung bom tidak tersimpan sebagai informasi permanen.
- Setelah keluar dari jangkauan penglihatan, tile kembali tertutup.
- Pemain harus kembali melakukan reveal untuk mengetahui kondisi tile tersebut.

Mekanisme ini menjadi salah satu elemen strategi utama permainan.

---

## 8. Health and Respawn System

### 8.1 Health System

Setiap pemain memiliki 3 nyawa.

Nyawa akan berkurang satu ketika pemain:

- Melakukan reveal pada tile bom.
- Menginjak tile bom.

### 8.2 Elimination

Ketika nyawa pemain mencapai nol:

1. Pemain mengalami eliminasi sementara.
2. Seluruh bendera yang dipasang oleh pemain tersebut dihapus.
3. Pemain menunggu proses respawn.
4. Pemain mendapatkan kembali 3 nyawa ketika respawn.

### 8.3 Respawn System

Pemain yang kehilangan seluruh nyawa akan respawn selama pertandingan masih berlangsung.

Ketentuan respawn:

- Posisi respawn dipilih secara acak.
- Pemain harus respawn pada tile aman.
- Pemain mendapatkan kembali 3 nyawa.
- Seluruh bendera milik pemain yang sebelumnya terpasang di arena dihapus.
- Posisi respawn harus berjarak setidaknya 50% dari lebar arena terhadap posisi lawan.

### 8.4 Respawn Protection

Pemain mendapatkan perlindungan untuk satu kejadian reveal bom setelah respawn.

Perlindungan ini tidak berlaku ketika pemain menginjak tile bom.

---

## 9. Collision System

Kedua pemain berada pada arena yang sama sehingga dapat mengalami tabrakan.

Aturan collision:

1. Dua pemain tidak dapat menempati tile yang sama.
2. Pemain yang bertabrakan dengan pemain lain tidak dapat melanjutkan pergerakan ke tile yang sedang ditempati.
3. Collision tidak mengurangi nyawa pemain.
4. Pemain dapat menghalangi jalur pergerakan lawan.
5. Tile yang memiliki bendera tetap dapat dilewati pemain.

Jika tile yang dilewati mengandung bom, pemain tetap kehilangan satu nyawa meskipun tile tersebut sudah memiliki bendera.

---

## 10. Scoring and Winning System

### 10.1 Scoring

Pemain mendapatkan satu poin untuk setiap bendera yang ditempatkan dengan benar pada tile bom.

Ketentuan:

- Bendera pada tile bom: +1 poin.
- Bendera pada tile aman: 0 poin.
- Bendera yang salah tidak memberikan poin.
- Skor dihitung berdasarkan jumlah bendera benar yang masih terpasang ketika pertandingan berakhir.

### 10.2 Match Timer

Setiap pertandingan memiliki batas waktu sesuai tingkat kesulitan.

Ketika waktu mencapai nol, pertandingan langsung berakhir.

### 10.3 Winner Determination

Pemenang ditentukan berdasarkan jumlah bendera benar yang dimiliki masing-masing pemain.

| Kondisi | Hasil |
|---|---|
| Skor Player 1 lebih tinggi | Player 1 menang |
| Skor Player 2 lebih tinggi | Player 2 menang |
| Skor kedua pemain sama | Draw |

---

## 11. User Interface and HUD

### 11.1 Main HUD

Setiap bagian split-screen menampilkan informasi pemain masing-masing.

Elemen HUD:

- Nama atau identitas pemain.
- Jumlah nyawa.
- Jumlah bendera tersisa.
- Jumlah skor.
- Posisi karakter.
- Arah hadap karakter.
- Highlight tile target.
- Area penglihatan 3 × 3.

### 11.2 Shared UI

Informasi yang ditampilkan secara bersama:

- Timer pertandingan.
- Tingkat kesulitan.
- Status pertandingan.
- Pengumuman pemenang.

### 11.3 Visual Feedback

Game perlu memberikan umpan balik visual yang jelas untuk:

- Tile yang sedang ditargetkan.
- Tile yang sudah di-reveal.
- Tile yang memiliki bendera.
- Tile yang berada dalam Fog of War.
- Pemain yang terkena ledakan.
- Pemain yang sedang respawn.

---

## 12. Art Direction and Visual Style

### 12.1 Visual Theme

Game menggunakan tema kawasan perkotaan terbengkalai yang berbahaya.

Elemen visual utama:

- Lingkungan perkotaan yang rusak.
- Asap tebal yang menutupi area permainan.
- Suasana gelap dan menegangkan.
- Grid arena yang terlihat jelas.
- Karakter dengan identitas visual berbeda.

### 12.2 Camera Perspective

Menggunakan perspektif Top-Down 2D agar pemain dapat melihat arena dan pergerakan karakter dari atas.

### 12.3 Visual Priority

Walaupun memiliki suasana gelap, informasi permainan harus tetap mudah dibaca.

Prioritas visual:

1. Karakter pemain.
2. Tile yang sedang ditargetkan.
3. Angka Minesweeper.
4. Bendera.
5. Indikator nyawa dan skor.
6. Efek asap dan lingkungan.

---

## 13. Technical Design

### 13.1 Core Systems

| System | Responsibility |
|---|---|
| Grid Manager | Mengatur struktur dan koordinat arena. |
| Bomb Generator | Menghasilkan posisi bom secara acak. |
| Tile Manager | Mengatur status setiap tile. |
| Player Controller | Mengatur pergerakan dan arah hadap pemain. |
| Input Manager | Membaca input kedua pemain. |
| Fog of War Manager | Mengatur area penglihatan pemain. |
| Exploration Manager | Menyimpan riwayat eksplorasi setiap pemain. |
| Flag Manager | Mengatur pemasangan dan penghapusan bendera. |
| Health Manager | Mengatur nyawa pemain. |
| Respawn Manager | Mengatur proses respawn. |
| Collision Manager | Mengatur tabrakan antar pemain. |
| Score Manager | Menghitung skor pemain. |
| Game Manager | Mengatur alur pertandingan. |
| UI Manager | Mengatur HUD dan tampilan permainan. |

### 13.2 Important Data Separation

Informasi eksplorasi harus disimpan secara terpisah untuk setiap pemain.

Contoh struktur konseptual:

- `player1_exploration_data`
- `player2_exploration_data`

Dengan demikian, tile yang sudah ditemukan oleh Player 1 belum tentu sudah ditemukan oleh Player 2.

### 13.3 Suggested Development Engine

Godot 4 dengan GDScript dapat digunakan sebagai salah satu pilihan untuk pengembangan game ini.

Pemilihan engine masih dapat disesuaikan dengan kebutuhan dan kemampuan tim pengembang.

---

## 14. Development Roadmap

Pengembangan dibagi menjadi beberapa tahap agar sistem permainan dapat diuji secara bertahap.

### Phase 1 — Core Grid

- Membuat arena berbentuk grid.
- Mengatur ukuran arena.
- Membuat sistem tile.
- Menghasilkan bom secara acak.
- Menghitung angka Minesweeper.

### Phase 2 — Player System

- Membuat dua karakter pemain.
- Mengatur kontrol WASD dan Arrow Keys.
- Membuat sistem arah hadap.
- Membuat grid-based movement.
- Mengatur collision antar pemain.

### Phase 3 — Minesweeper Interaction

- Membuat sistem reveal tile.
- Membuat sistem angka Minesweeper.
- Membuat sistem ledakan bom.
- Membuat sistem pemasangan dan penghapusan bendera.

### Phase 4 — Fog of War

- Membuat jangkauan penglihatan 3 × 3.
- Membuat Fog of War terpisah.
- Membuat sistem exploration memory.
- Mengatur persistensi informasi tile aman.
- Mengatur penyembunyian kembali tile bom.

### Phase 5 — Competitive System

- Membuat sistem nyawa.
- Membuat sistem eliminasi.
- Membuat sistem respawn.
- Membuat sistem respawn protection.
- Membuat sistem skor.
- Membuat timer pertandingan.
- Membuat penentuan pemenang.

### Phase 6 — UI and Polish

- Membuat tampilan split-screen.
- Membuat HUD kedua pemain.
- Membuat efek asap.
- Membuat animasi ledakan.
- Membuat efek visual interaksi tile.
- Melakukan playtesting dan balancing.

---

## 15. Design Constraints and Notes

Beberapa aturan penting yang harus dipertahankan selama pengembangan:

1. Kedua pemain bermain pada arena yang sama.
2. Informasi eksplorasi kedua pemain tidak boleh tercampur.
3. Posisi bom tidak berubah selama pertandingan.
4. Tile bom yang keluar dari jangkauan penglihatan kembali tersembunyi.
5. Informasi tile aman yang pernah ditemukan tetap tersimpan.
6. Bendera yang benar menjadi sumber poin.
7. Bendera pemain dihapus ketika pemain kehilangan seluruh nyawa.
8. Pemain tidak dapat menempati tile yang sama.
9. Pemain tetap dapat menginjak tile yang memiliki bendera.
10. Pertandingan berakhir ketika timer mencapai nol.

---

**End of Game Design Document — Minefield v1.1**