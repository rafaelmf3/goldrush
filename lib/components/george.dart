import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/geometry.dart';
import 'package:flame/sprite.dart';
import 'package:goldrush/components/hud/hud.dart';
import 'package:goldrush/components/skeleton.dart';
import 'package:goldrush/components/zombie.dart';
import 'package:goldrush/utils/math_utils.dart';
import 'package:flame/input.dart';
import 'character.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:audioplayers/audioplayers.dart';

class George extends Character {
  George(
      {required this.hud,
      required Vector2 position,
      required Vector2 size,
      required double speed})
      : super(position: position, size: size, speed: speed);

  final HudComponent hud;
  late double walkingSpeed, runningSpeed;
  late Vector2 targetLocation;
  bool movingToTouchedLocation = false;
  bool isMoving = false;
  late AudioPlayer audioPlayerRunning;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    walkingSpeed = speed;
    runningSpeed = speed * 2;

    var spriteImages = await Flame.images.load('george.png');
    final spriteSheet =
        SpriteSheet(image: spriteImages, srcSize: Vector2(width, height));

    downAnimation =
        spriteSheet.createAnimationByColumn(column: 0, stepTime: 0.2);
    leftAnimation =
        spriteSheet.createAnimationByColumn(column: 1, stepTime: 0.2);
    upAnimation = spriteSheet.createAnimationByColumn(column: 2, stepTime: 0.2);
    rightAnimation =
        spriteSheet.createAnimationByColumn(column: 3, stepTime: 0.2);

    animation = downAnimation;
    playing = false;
    anchor = Anchor.center;

    addHitbox(HitboxRectangle());

    await FlameAudio.audioCache
        .loadAll(['sounds/enemy_dies.wav', 'sounds/running.wav']);
  }

  void moveToLocation(TapUpInfo info) {
    targetLocation = info.eventPosition.game;
    movingToTouchedLocation = true;
  }

  @override
  void onCollision(Set<Vector2> points, Collidable other) {
    super.onCollision(points, other);

    if (other is Zombie || other is Skeleton) {
      other.removeFromParent();
      hud.scoreText.setScore(10);

      FlameAudio.play('sounds/enemy_dies.wav', volume: 1.0);
    }
  }

  @override
  void update(double dt) async {
    super.update(dt);

    speed = hud.runButton.buttonPressed ? runningSpeed : walkingSpeed;

    if (!hud.joystick.delta.isZero()) {
      position.add(hud.joystick.relativeDelta * speed * dt);
      playing = true;
      movingToTouchedLocation = false;
      if (!isMoving) {
        isMoving = true;
        audioPlayerRunning =
            await FlameAudio.loopLongAudio('sounds/running.wav', volume: 1.0);
      }

      switch (hud.joystick.direction) {
        case JoystickDirection.up:
        case JoystickDirection.upRight:
        case JoystickDirection.upLeft:
          animation = upAnimation;
          currentDirection = Character.up;
          break;
        case JoystickDirection.down:
        case JoystickDirection.downRight:
        case JoystickDirection.downLeft:
          animation = downAnimation;
          currentDirection = Character.down;
          break;
        case JoystickDirection.left:
          animation = leftAnimation;
          currentDirection = Character.left;
          break;
        case JoystickDirection.right:
          animation = rightAnimation;
          currentDirection = Character.right;
          break;
        case JoystickDirection.idle:
          animation = null;
          break;
      }
    } else {
      if (movingToTouchedLocation) {
        if (!isMoving) {
          isMoving = true;
          audioPlayerRunning =
              await FlameAudio.loopLongAudio('sounds/running.wav', volume: 1.0);
        }

        position += (targetLocation - position).normalized() * (speed * dt);

        double threshhold = 1.0;
        var difference = targetLocation - position;
        if (difference.x.abs() < threshhold &&
            difference.y.abs() < threshhold) {
          stopAnimations();

          audioPlayerRunning.stop();
          isMoving = false;

          movingToTouchedLocation = false;
          return;
        }

        playing = true;
        var angle = getAngle(position, targetLocation);
        if ((angle > 315 && angle < 360) || (angle > 0 && angle < 45)) {
          // Moving right
          animation = rightAnimation;
          currentDirection = Character.right;
        } else if (angle > 45 && angle < 135) {
          // Moving down
          animation = downAnimation;
          currentDirection = Character.down;
        } else if (angle > 135 && angle < 225) {
          // Moving left
          animation = leftAnimation;
          currentDirection = Character.left;
        } else if (angle > 225 && angle < 315) {
          // Moving up
          animation = upAnimation;
          currentDirection = Character.up;
        }
      } else {
        if (playing) {
          stopAnimations();
        }
        if (isMoving) {
          isMoving = false;
          audioPlayerRunning.stop();
        }
      }
    }
  }

  void stopAnimations() {
    animation?.currentIndex = 0;
    playing = false;
  }

  void onPaused() {
    if (isMoving) {
      audioPlayerRunning.pause();
    }
  }

  void onResumed() async {
    if (isMoving) {
      audioPlayerRunning.resume();
    }
  }
}
