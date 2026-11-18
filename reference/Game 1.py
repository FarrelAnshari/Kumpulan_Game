
import pygame
import math
import random

# =====================================
# 1. INISIALISASI GAME
# =====================================

pygame.init()

WIDTH = 800
HEIGHT = 600

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("BIKE RUSH - My First Racing Game")

clock = pygame.time.Clock()

# Warna
WHITE = (255, 255, 255)
BLACK = (20, 20, 25)
ORANGE = (255, 145, 0)
RED = (220, 55, 55)
GREEN = (30, 150, 65)
DARK_GREEN = (20, 105, 55)
ROAD = (75, 70, 65)

# Font
font = pygame.font.SysFont("arial", 28, bold=True)
small_font = pygame.font.SysFont("arial", 18, bold=True)

# =====================================
# 2. VARIABEL GAME
# =====================================

player_x = WIDTH // 2
player_y = 465

player_speed = 7
game_speed = 160

score = 0
road_offset = 0

running = True

# =====================================
# 3. MEMBUAT BACKGROUND
# =====================================

def draw_background():

    # Langit
    screen.fill((115, 75, 135))

    # Gradient sunset
    for y in range(0, 210):
        ratio = y / 210

        color = (
            int(110 + ratio * 120),
            int(65 + ratio * 65),
            int(130 - ratio * 40)
        )

        pygame.draw.line(
            screen,
            color,
            (0, y),
            (WIDTH, y)
        )

    # Matahari
    pygame.draw.circle(
        screen,
        (255, 215, 125),
        (400, 205),
        65
    )

    # Pegunungan
    pygame.draw.polygon(
        screen,
        (105, 55, 100),
        [
            (0, 250),
            (100, 185),
            (220, 250),
            (350, 175),
            (500, 250),
            (650, 180),
            (800, 245),
            (800, 300),
            (0, 300)
        ]
    )

    # Gurun
    pygame.draw.rect(
        screen,
        (225, 160, 95),
        (0, 260, WIDTH, 340)
    )


# =====================================
# 4. MENGGAMBAR JALAN
# =====================================

def road_width(t):
    return 35 + (t ** 1.15) * 340


def draw_road():

    horizon = 265
    center = WIDTH // 2

    # Jalan utama
    pygame.draw.polygon(
        screen,
        ROAD,
        [
            (center - 35, horizon),
            (center + 35, horizon),
            (center + 375, HEIGHT),
            (center - 375, HEIGHT)
        ]
    )

    # Pinggir jalan
    pygame.draw.line(
        screen,
        WHITE,
        (center - 35, horizon),
        (center - 375, HEIGHT),
        9
    )

    pygame.draw.line(
        screen,
        WHITE,
        (center + 35, horizon),
        (center + 375, HEIGHT),
        9
    )

    # Marka jalan bergerak
    for lane in [-1, 1]:

        for i in range(12):

            t1 = ((i / 12) + road_offset) % 1
            t2 = min(t1 + 0.035, 1)

            y1 = horizon + (t1 ** 2) * (HEIGHT - horizon)
            y2 = horizon + (t2 ** 2) * (HEIGHT - horizon)

            w1 = road_width(t1)
            w2 = road_width(t2)

            x1 = center + lane * w1 / 3
            x2 = center + lane * w2 / 3

            pygame.draw.line(
                screen,
                WHITE,
                (int(x1), int(y1)),
                (int(x2), int(y2)),
                max(2, int(t1 * 8))
            )


# =====================================
# 5. MENGGAMBAR KAKTUS
# =====================================

def draw_cactus(x, y, size):

    color = DARK_GREEN

    # Batang utama
    pygame.draw.rect(
        screen,
        color,
        (x, y, size, size * 2)
    )

    # Cabang kiri
    pygame.draw.rect(
        screen,
        color,
        (x - size, y + size // 2, size, size // 3)
    )

    pygame.draw.rect(
        screen,
        color,
        (x - size, y + size // 3, size // 3, size)
    )

    # Cabang kanan
    pygame.draw.rect(
        screen,
        color,
        (x + size // 2, y + size, size, size // 3)
    )

    pygame.draw.rect(
        screen,
        color,
        (x + size, y + size // 2, size // 3, size)
    )


def draw_desert_objects():

    # Objek dekorasi sederhana di sisi jalan
    for i in range(7):

        size = 8 + i * 2
        y = 280 + i * 40

        draw_cactus(90 - i * 12, y, size)
        draw_cactus(680 + i * 12, y, size)


# =====================================
# 6. MENGGAMBAR MOTOR
# =====================================

def draw_motor(x, y):

    # Roda belakang
    pygame.draw.ellipse(
        screen,
        BLACK,
        (x - 17, y + 60, 34, 65)
    )

    # Body motor
    pygame.draw.polygon(
        screen,
        (35, 55, 105),
        [
            (x - 35, y + 45),
            (x - 25, y + 10),
            (x + 25, y + 10),
            (x + 35, y + 45),
            (x + 20, y + 75),
            (x - 20, y + 75)
        ]
    )

    # Bagian belakang motor
    pygame.draw.rect(
        screen,
        RED,
        (x - 15, y + 42, 30, 22)
    )

    # Lampu belakang
    pygame.draw.rect(
        screen,
        (255, 40, 30),
        (x - 8, y + 65, 16, 8)
    )

    # Badan pengendara
    pygame.draw.polygon(
        screen,
        ORANGE,
        [
            (x - 18, y + 5),
            (x - 12, y - 35),
            (x + 12, y - 35),
            (x + 18, y + 5)
        ]
    )

    # Helm
    pygame.draw.circle(
        screen,
        WHITE,
        (x, y - 38),
        20
    )

    # Kaca helm
    pygame.draw.ellipse(
        screen,
        ORANGE,
        (x - 5, y - 43, 15, 20)
    )

    # Stang
    pygame.draw.line(
        screen,
        BLACK,
        (x - 35, y + 10),
        (x + 35, y + 10),
        6
    )


# =====================================
# 7. HUD SCORE DAN SPEED
# =====================================

def draw_hud():

    # Kotak SCORE
    pygame.draw.rect(
        screen,
        (35, 25, 55),
        (25, 20, 170, 80),
        border_radius=12
    )

    score_text = small_font.render(
        "SCORE",
        True,
        WHITE
    )

    score_value = font.render(
        str(score),
        True,
        (255, 225, 40)
    )

    screen.blit(score_text, (40, 28))
    screen.blit(score_value, (40, 48))

    # Kotak SPEED
    pygame.draw.rect(
        screen,
        (35, 25, 55),
        (605, 20, 170, 80),
        border_radius=12
    )

    speed_text = small_font.render(
        "SPEED",
        True,
        WHITE
    )

    speed_value = font.render(
        str(game_speed),
        True,
        (70, 255, 110)
    )

    screen.blit(speed_text, (620, 28))
    screen.blit(speed_value, (620, 48))


# =====================================
# 8. GAME LOOP
# =====================================

while running:

    clock.tick(60)

    # Event
    for event in pygame.event.get():

        if event.type == pygame.QUIT:
            running = False

    # Kontrol motor
    keys = pygame.key.get_pressed()

    if keys[pygame.K_LEFT] or keys[pygame.K_a]:
        player_x -= player_speed

    if keys[pygame.K_RIGHT] or keys[pygame.K_d]:
        player_x += player_speed

    # Batas pergerakan motor
    player_x = max(80, min(player_x, 720))

    # Animasi jalan
    road_offset += game_speed / 10000

    if road_offset >= 1:
        road_offset -= 1

    # Score
    score += 1

    # =================================
    # GAMBAR SEMUA OBJEK
    # =================================

    draw_background()
    draw_desert_objects()
    draw_road()
    draw_motor(player_x, player_y)
    draw_hud()

    pygame.display.flip()


# =====================================
# 9. KELUAR DARI GAME
# =====================================

pygame.quit()
