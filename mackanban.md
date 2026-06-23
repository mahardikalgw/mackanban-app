# Product Requirements Document (PRD)

## Project Name

TaskBar

Tagline:
"Your personal Kanban board in the macOS menu bar."

---

# 1. Overview

TaskBar adalah aplikasi macOS berbasis SwiftUI yang berjalan di Menu Bar dan memungkinkan pengguna mengelola pekerjaan menggunakan Kanban Board tanpa harus membuka aplikasi besar seperti Trello atau Notion.

Pengguna dapat mengklik ikon di menu bar untuk membuka panel Kanban yang ringan dan cepat.

Target utama adalah developer, mahasiswa, freelancer, dan pekerja remote yang membutuhkan task management sederhana dan cepat.

---

# 2. Goals

### Business Goals

* Menyediakan task manager ringan untuk macOS
* Menjadi alternatif Trello untuk kebutuhan personal
* Dapat dijual di Mac App Store

### User Goals

* Menambah task dengan cepat
* Melihat progres pekerjaan dalam sekali klik
* Tidak perlu membuka browser
* Tetap fokus bekerja

---

# 3. Target Users

## Primary Users

* Software Engineer
* UI/UX Designer
* Freelancer
* Mahasiswa

## Secondary Users

* Content Creator
* Product Manager
* Startup Founder

---

# 4. Core Features

## 4.1 Menu Bar App

User melihat icon aplikasi di menu bar macOS.

Saat icon diklik:

* Panel muncul
* Kanban Board ditampilkan
* Tidak membuka window terpisah

---

## 4.2 Kanban Board

Default column:

* Todo
* Doing
* Done

User dapat:

* Menambah task
* Menghapus task
* Mengedit task
* Drag & Drop task antar column

---

## 4.3 Quick Add Task

Shortcut:

⌘ + Shift + N

Popup kecil muncul:

Title:
[________________]

Description:
[________________]

[Save]

---

## 4.4 Task Detail

Field:

* Title
* Description
* Priority
* Due Date
* Tags

Priority:

* Low
* Medium
* High

---

## 4.5 Search

User dapat mencari task berdasarkan:

* Judul
* Tag
* Status

---

## 4.6 Persistence

Semua data tersimpan lokal menggunakan:

* SwiftData

atau

* SQLite

Data tetap tersedia setelah aplikasi ditutup.

---

# 5. Future Features (V2)

## V2.1 Multiple Boards

Contoh:

Personal

Work

Side Projects

---

## V2.2 Pomodoro Timer

Timer:

25 menit kerja

5 menit istirahat

Terintegrasi dengan task.

---

## V2.3 iCloud Sync

Sinkronisasi otomatis antar:

* MacBook
* iMac
* Mac Mini

---

## V2.4 Notifications

Reminder sebelum deadline.

---

## V2.5 Markdown Support

Task description mendukung:

* Checklist
* Heading
* Code Block

---

# 6. User Flow

## Menambah Task

1. User klik icon menu bar
2. Panel terbuka
3. Klik tombol "+"
4. Isi task
5. Klik Save
6. Task muncul di Todo

---

## Memindahkan Task

1. User drag task
2. Drop ke column lain
3. Status berubah otomatis

---

# 7. UI Layout

Menu Bar

● TaskBar

↓

Panel

---

## Search...

TODO            DOING           DONE

[Task A]        [Task C]        [Task E]

[Task B]        [Task D]

---

* New Task

---

# 8. Technical Requirements

## Platform

macOS 15+

## Language

Swift

## Framework

SwiftUI

## Storage

SwiftData

## Architecture

MVVM

Layers:

* View
* ViewModel
* Model
* Repository

---

# 9. Data Model

Task

id: UUID

title: String

description: String

status: TaskStatus

priority: Priority

createdAt: Date

updatedAt: Date

dueDate: Date?

tags: [String]

TaskStatus

* todo
* doing
* done

Priority

* low
* medium
* high

---

# 10. Success Metrics

MVP

* User dapat membuat task
* User dapat drag & drop task
* Data tersimpan lokal
* Launch time < 1 detik
* Menu bar interaction < 200ms

V1

* 100+ task tanpa lag
* Multiple board support
* iCloud sync
w