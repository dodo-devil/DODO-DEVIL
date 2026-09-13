-- ⚠️ IMPORTANT: Put this code at the VERY TOP of your Main Script (before obfuscating) ⚠️

local ProtectionConfig = {
    -- 🛑 CRITICAL: This MUST exactly match the 'Secret' value in your Key System's Config!
    -- If your Key System has: Secret = "Test"
    -- Then this must also be: SecretKey = "Test"
    SecretKey = "i-m-devil4you",

    -- The name of your Hub (shown in the kick message if they try to bypass)
    HubName = "DODO-DEVIL"
}

-- Anti-Bypass Logic: Checks if the Key System successfully set the global variable
if not _G[ProtectionConfig.SecretKey] then
    local player = game:GetService("Players").LocalPlayer
    if player then
        player:Kick("\n🛡️ Unauthorized Execution 🛡️\n\nPlease use the official Key System to run " .. ProtectionConfig.HubName)
    end
    return -- Stops the rest of the script from loading!
end


--==============================================================
-- SPECIAL GK BOT V23.6 - CURVE + HITBOX-CONTACT CONTROLLER
-- ONE LOCALSCRIPT ONLY
--
-- StarterPlayer
--   StarterPlayerScripts
--      SpecialGKBotV23
--
-- V23.6 ersetzt alle früheren Versionen vollständig.
-- Nicht mehrere Versionen gleichzeitig starten.
--
-- GRUNDSÄTZE
-- 1. Kein erfundenes Tor: zuerst echte Goal-Hitboxes kalibrieren.
-- 2. Kein reines Welt-X: Bewegung arbeitet in einem lokalen Torraum.
-- 3. Weltbewegung wird in den kameraabhängigen ControlModule-Input
--    umgerechnet (bewährter V16/V20-Ansatz).
-- 4. Kein beliebiges Risk-Scoring: RUN/DIVE werden über gemessene
--    Erreichbarkeit entschieden.
-- 5. Grab benutzt die echte grüne GoalkeeperGrab-Anzeige aus V20.
-- 6. Grab ist dauerhaft ARMED, besitzt aber nie den Movement-State.
-- 7. Nur bestätigtes HoldingBall darf Bewegung stoppen.
-- 8. Grab und Dive starten zuerst über die nativen Movement-Inputs.
-- 9. Bewegung respektiert die echte GoalkeeperZone und stoppt vor Barrieren.
-- 10. Keine Hitbox-Vergrößerung, kein Teleport und kein eigener Server-Remote.
-- 11. Tor, Zone und Positionsquelle bleiben bis zu einer echten Rekalibrierung gesperrt.
-- 12. Ein unmöglicher Referenz-/Zielsprung stoppt, statt die Laufrichtung umzuschalten.
-- 13. Dive, Kontakt, Aufstehen und Rückkehr sind getrennte, explizite Phasen.
-- 14. Eine erkannte Abwehr startet eine neue Ballbahn und gibt einen Rebound-Dive frei.
-- 15. Curve wird schrittweise, geschwindigkeitsabhängig und pro Messframe gecacht simuliert.
-- 16. Slow-Shot-Dives warten auf das gelernte zeitabhängige GoalieGrab-Hitboxfenster.
-- 17. Dive-Höhe folgt zuerst der Trefferhöhe; falsche native Hoch-/Tief-Polarität korrigiert sich selbst.
--==============================================================

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================
-- CONFIG
-- Alle Distanzen werden soweit möglich aus der echten Torbreite
-- abgeleitet. Nur Reaktions-/Netzwerkzeiten bleiben konfiguriert.
--==============================================================

local CONFIG = {
	-- Ball
	BallNames = {ClientBall = 120, ServerBall = 115, GameBall = 100, Ball = 35},
	BallRadius = 0.675,
	ExactBallPath = {"Balls", "GameBall"},
	DatasetMaximumAge = 0.35,
	MaximumLatencyExtrapolation = 0.16,
	NetworkPingWeight = 0.50,
	FilterAlphaSlow = 0.34,
	FilterAlphaFast = 0.78,
	FilterBetaSlow = 0.10,
	FilterBetaFast = 0.42,
	FilterGamma = 0.075,
	FilterResetDistance = 7.5,
	FilterMaximumStep = 0.12,
	CurveConfirmationFrames = 3,
	CurveMinimumAcceleration = 4.0,
	CurveMaximumAcceleration = 80,
	CurveConsistencyDot = 0.72,
	CurvePredictionStep = 0.015,
	CurveSlowSpeedBoostMaximum = 2.25,
	CurveAccelerationChangeRate = 7.0,
	CurveGroundHeightTolerance = 0.85,
	BallDiscoveryInterval = 0.45,
	BallSwitchMargin = 18,
	BallTrajectoryLockMinimumSpeed = 6,
	BallContinuityDistance = 18,
	HistoryWindow = 0.28,
	MaxHistory = 20,
	MeasurementWindow = 10,
	MeasurementMaximumAge = 0.24,
	RegressionVelocityBlend = 0.34,
	MaxBallSpeed = 520,
	KickSpeedJump = 9,
	KickMinimumSpeed = 14,
	RicochetAngle = 55,
	RawVelocityWindow = 0.16,
	AlwaysRawAboveSpeed = 65,
	PhysicalBallMaximumSeparation = 8,
	ForceVelocityClamp = 180,
	ImmediateVelocityWindow = 0.085,
	FastShotImmediateSpeed = 70,
	ExtremeShotSpeed = 115,
	FastShotImmediateTime = 0.50,
	FastShotMinimumDiveLead = 0.58,
	ExtremeSpeedMinimumDiveLead = 0.78,
	SlowShotSpeed = 54,
	PredictedCatchRadius = 2.25,
	MediumShotDiveBuffer = 0.11,
	MediumShotMaximumDiveLead = 0.56,
	MediumShotRunReachBonus = 0.70,
	GroundMoveGrabMaxSpeed = 74,
	SlowShotDiveCommitTime = 0.26,
	GroundShotDiveCommitTime = 0.20,
	SlowShotDiveBuffer = 0.08,
	SlowShotMaximumDiveLead = 0.48,
	SlowAimAlpha = 0.30,
	MediumAimAlpha = 0.46,
	CloseShotOriginRatio = 0.85,
	FarShotOriginRatio = 2.55,
	CloseShotMaximumDiveLead = 0.48,
	FarShotMaximumDiveLead = 0.60,
	FarCornerMaximumDiveLead = 0.72,
	NormalAimAlpha = 0.55,
	FastAimAlpha = 0.86,
	SlowShotRunReachBonus = 1.15,
	SlowCollectionMinimumTime = 0.95,
	SlowCollectionMaximumDistance = 7.5,
	ThreatLooseBallLockTime = 0.85,
	ThreatMinimumGoalwardSpeed = 8,
	DeflectionContactDistance = 5.75,
	DeflectionSpeedChange = 7.5,
	WeakDeflectionSpeedChange = 2.2,
	DeflectionMinimumAngle = 26,
	DeflectionMemoryTime = 0.32,
	ReboundDefenseTime = 1.35,

	-- Goal-Kalibrierung
	GoalRefreshInterval = 2,
	MinimumPostHeight = 4,
	MinimumPostAspect = 1.35,
	MinimumGoalWidth = 8,
	-- Bekannte Standardgeometrie aus der funktionierenden V20-Version.
	-- Sie wird NUR benutzt, wenn Workspace.Hitboxes.Goals fehlt oder eine
	-- neue Map-Struktur nicht sicher ausgewertet werden kann. Dadurch bleibt
	-- der Bot nicht mehr vollständig stehen, nur weil ein Ordner umbenannt wurde.
	EnableV20GoalFallback = true,
	FallbackPositiveGoalZ = 225,
	FallbackNegativeGoalZ = -225,
	FallbackGoalCenterX = 0,
	FallbackGoalHalfWidth = 12.45,
	FallbackGoalBottomY = 6.98,
	FallbackGoalTopY = 16.68,
	HomeDepthWidthRatio = 0.16,
	HomeDepthMin = 1.35,
	HomeDepthMax = 2.75,
	MaximumDepthWidthRatio = 0.66,
	MaximumDepthMin = 6.0,
	MaximumDepthMax = 8.5,
	GoalLineMinimumDepth = 0.25,
	PostInsidePadding = 0.30,
	SaveOutsidePadding = 0.65,
	DangerDepthWidthRatio = 1.35,
	GoalWidthMargin = 1.0,
	GoalHeightMargin = 1.0,

	-- Movement / System Identification
	ArrivalEnterDistance = 0.38,
	ArrivalExitDistance = 0.72,
	FullInputDistance = 1.15,
	ZoneBoundaryInset = 0.85,
	ZoneBoundaryRetreatInset = 1.65,
	ZoneBoundaryGuardDistance = 0.55,
	BallChaseBoundaryTolerance = 0.35,
	BoundaryStuckChecks = 2,
	BoundaryRetreatTime = 0.75,
	DefaultRunSpeed = 11.5,
	DefaultRunAcceleration = 32,
	MinimumRunSpeed = 6,
	MaximumRunSpeed = 22,
	MinimumRunAcceleration = 12,
	MaximumRunAcceleration = 75,
	LearnAlpha = 0.10,
	MovementStuckCheckTime = 0.38,
	MovementStuckMinDistance = 0.75,
	MovementStuckMinProgress = 0.045,
	MovementRepairCooldown = 0.70,
	WrongDirectionMinimumTravel = 0.08,
	WrongDirectionMaximumAlignment = -0.30,
	CorrectDirectionMinimumAlignment = 0.25,
	WrongDirectionConfirmations = 2,
	CorrectDirectionConfirmations = 2,
	LockedWrongDirectionConfirmations = 4,
	PositionMaximumSpeed = 125,
	PositionJumpTolerance = 5.0,
	PositionSourceMaximumFailures = 8,
	TargetJumpMaximumDistance = 35,
	ReferenceDepthTolerance = 2.5,
	GoalLockMinimumAdvantage = 20,
	ReactionLatency = 0.050,
	RunSafetyMargin = 0.40,
	ApproachBehindBall = 1.25,
	LooseBallMaximumSpeed = 42,
	LooseBallMaximumDistance = 10,

	-- V16 Shooter-Anticipation, jetzt vollständig im lokalen Torraum.
	PossessorSearchDistance = 10,
	PossessorMinimumScore = 48,
	PossessorMemoryTime = 0.42,
	ShooterFacingMinimum = 0.08,
	ShooterAimMinimumWeight = 0.03,
	ShooterAimMaximumWeight = 0.14,
	AnticipationSmoothingAlpha = 0.16,
	AnticipationMaximumLateralRatio = 0.36,
	AnticipationProjectionMaximumTime = 45,
	AnticipationMinimumConfidence = 0.45,
	AnticipationStablePossessionTime = 0.12,
	AnticipationMaximumBallDistance = 6.0,
	AnticipationMaximumBallSpeed = 24,
	AnticipationMaximumGoalwardSpeed = 7,

	-- Replizierter Pre-Shot-Sensor. Er liest nur Zustände, die dieser Client
	-- tatsächlich sehen darf. Fremde Eingaben/FireServer-Aufrufe werden NICHT
	-- abgefangen. Vor dem Release ist nur eine kleine Positionskorrektur erlaubt.
	PreShotMinimumConfidence = 0.58,
	PreShotStableTime = 0.10,
	PreShotMemoryTime = 0.30,
	PreShotMaximumBallSpeed = 24,
	PreShotMaximumGoalwardSpeed = 7,
	PreShotMaximumBallDistance = 6.5,
	PreShotMinimumWeight = 0.035,
	PreShotMaximumWeight = 0.12,
	PreShotMaximumLateralRatio = 0.34,
	PreShotReleaseMemory = 0.20,
	ShootLookThetaMinimum = -0.2618,
	ShootLookThetaMaximum = 0.3491,
	KnownKickAnimations = {
		["15016646690"] = true,
		["15016663078"] = true,
		["15016672875"] = true,
		["15016749359"] = true,
	},

	-- Rein mathematische Messlinien, keine Parts und keine Ballkollision.
	VirtualGateBlend = 0.35,
	VirtualGateGroundBlend = 0.12,
	VirtualGateMaximumAge = 0.90,
	VirtualGateMinimumSpeed = 2,
	VirtualGateMaximumSpeed = 520,

	PredictionMinimumHistory = 5,
	PredictionErrorScale = 2.8,
	PredictionVelocityNoiseScale = 0.42,
	PredictionStableTime = 0.10,
	PredictionDiveConfidence = 0.52,
	PredictionEmergencyOverrideTime = 0.22,
	UncertainDiveExtraFrames = 2,
	RunArrivalTolerance = 0.035,
	DiveArrivalTolerance = 0.045,
	PositionPostGuardRatio = 0.88,

	-- Prediction / Modellwahl
	PredictionStep = 1 / 60,
	InterceptRefinementIterations = 5,
	InterceptTimeTolerance = 0.0015,
	MaximumPredictionTime = 3.0,
	MinimumGoalwardSpeed = 1.0,
	AccelerationClamp = 95,
	ModelErrorAlpha = 0.18,
	ModelSwitchMargin = 0.08,
	PredictionBaseUncertainty = 0.16,
	PredictionAgeUncertaintyScale = 5.0,
	PredictionTimeUncertaintyScale = 0.34,
	PredictionCorridorLateralScale = 1.15,
	PredictionCorridorVerticalScale = 0.80,
	OutcomeBiasInitialAlpha = 0.18,
	OutcomeBiasStableAlpha = 0.08,
	OutcomeBiasMinimumConfidence = 0.32,
	OutcomeBiasMaximum = 2.5,
	GroundRayDistance = 7,
	GroundTolerance = 0.95,
	GroundVerticalLimit = 10,
	DefaultGroundDeceleration = 7,
	MaximumGroundDeceleration = 35,

	-- Grab: bekannter V20-Vertrag
	GrabIndicatorRefresh = 0.30,
	GrabSanityDistance = 4.25,
	GrabCooldown = 0.16,
	GrabRetryDelay = 0.075,
	GrabReleaseDelay = 0.11,
	GrabConfirmWindow = 0.42,
	GrabPrepareMinimumTime = 0.055,
	GrabPrepareMaximumTime = 0.20,
	GrabPrepareMaximumDistance = 6.5,
	HoldingConfirmationDistance = 8.0,
	GrabPhysicalFallbackDistance = 3.10,
	GrabPhysicalFallbackMaxRelativeSpeed = 80,
	DiveGrabFallbackMaxRelativeSpeed = 145,
	GoalieGrabHitboxPadding = 0.75,
	PreferNativeBallDataset = true,

	-- Nativer Dive
	DiveDefault = true,
	DiveCooldown = 0.38,
	DiveInputHold = 0.075,
	DiveMinimumActiveTime = 0.24,
	DiveMaximumActiveTime = 0.95,
	DiveMotionStopSpeed = 1.20,
	DiveMotionStopConfirmTime = 0.10,
	DiveMotionStartDistance = 0.08,
	DiveMaximumMotionSamples = 64,
	DiveContactWindowTime = 0.22,
	GetUpMinimumTime = 0.18,
	GetUpMaximumTime = 0.78,
	RecoverySettleSpeed = 1.25,
	RecoveryArrivalDistance = 0.62,
	KeeperProjectionMaximumTime = 0.30,
	RecoveryHomeSpeed = 0.85,
	RecoveryThreatMaximumTime = 0.58,
	DiveInputLatency = 0.045,
	DiveServerMargin = 0.028,
	DiveResidualPingWeight = 0.22,
	DefaultDiveReach = 4.0,
	MinimumDiveReach = 2.6,
	MaximumDiveReach = 7.5,
	DiveLearnAlpha = 0.16,
	DefaultDiveContactTime = 0.42,
	MinimumDiveContactTime = 0.14,
	MaximumDiveContactTime = 0.62,
	DiveContactLearnAlpha = 0.18,
	DiveContactBuffer = 0.055,
	DiveHitboxSampleStep = 0.025,
	DiveHitboxMinimumBins = 5,
	DiveHitboxMinimumContactTime = 0.07,
	DiveHitboxLearnAlpha = 0.24,
	DiveHitboxContactPadding = 0.16,
	DiveHitboxMaximumExtent = 5.5,
	DiveHitboxLeadSafety = 0.035,
	DiveVerticalPolarityThreshold = 0.30,
	DiveMinimumLead = 0.28,
	DiveMaximumLead = 1.35,
	FastShotExtraLead = 0.15,
	FarShotDistance = 5.7,
	FarShotMinimumLead = 0.94,
	CornerStartRatio = 0.70,
	ExtremeCornerRatio = 0.86,
	CornerRequiredLateral = 2.25,
	CornerMinimumLead = 0.78,
	ExtremeCornerMinimumLead = 0.96,
	HighCornerMinimumLead = 1.06,
	CornerDiveExtraLead = 0.10,
	EmergencyDiveTime = 0.23,
	ExtremeEmergencyTime = 0.115,
	FastRunOnlyLateral = 0.82,
	EmergencyCenterRange = 0.68,
	CenterBlockRange = 1.30,
	CenterHighBlockRange = 1.15,
	NormalDiveConfirmFrames = 2,
	HighBallRelative = 0.70,
	LowBallRelative = 0.28,
	DiveTierHeightScoreWeight = 1.8,
	DiveTierReachScoreWeight = 0.12,
	DiveVerticalToleranceLow = 1.45,
	DiveVerticalToleranceMid = 1.75,
	DiveVerticalToleranceHigh = 1.55,
	RunDirectionChangePenalty = 0.09,
	RunDepthPenaltyScale = 0.035,
	SlowCollectStageDistance = 2.7,

	-- Kompakte GUI / Diagnose
	DiagnosticsInterval = 0.16,
	ControlRepairInterval = 0.75,
}

local COLORS = {
	BG = Color3.fromRGB(15, 17, 22),
	BUTTON = Color3.fromRGB(37, 41, 50),
	TEXT = Color3.fromRGB(242, 244, 248),
	MUTED = Color3.fromRGB(154, 161, 176),
	GREEN = Color3.fromRGB(62, 190, 111),
	BLUE = Color3.fromRGB(72, 142, 246),
	ORANGE = Color3.fromRGB(244, 151, 54),
	RED = Color3.fromRGB(221, 76, 82),
}

--==============================================================
-- ALTE VERSIONEN / BINDS ENTFERNEN
--==============================================================

for _, name in ipairs({
	"SpecialGKV16", "SpecialGKV17", "SpecialGKV18", "SpecialGKV19",
	"SpecialGKV20", "SpecialGKV21", "SpecialGKV22",
	"SpecialGKV23",
}) do
	local old = PlayerGui:FindFirstChild(name)
	if old then old:Destroy() end
end

--==============================================================
-- RUNTIME
--==============================================================

local Options = {
	Bot = true,
	AutoGrab = true,
	AutoDive = CONFIG.DiveDefault,
	Anticipation = false,
	PreShot = true,
}

local Runtime = {
	Movement = nil,
	Wrapper = nil,
	Auxillary = nil,
	ClientBall = nil,
	ChickynoidDetected = false,
	GrabDriver = "WAIT",
	ForcedMoveVector = nil,
	ForcedMoveOwner = nil,
	WorldTarget = nil,
	AllowOutsidePosts = false,
	TargetReason = "NONE",
	TargetArrived = false,
	BoundaryStuckCount = 0,
	BoundaryRetreatUntil = 0,
	BoundaryRetreatTarget = nil,
	DefendedGoal = nil,
	CalibrationOK = false,
	State = "STARTING",
	Action = "NONE",
	Event = "START",
	SavePhase = "CALIBRATING",
	SavePhaseSince = 0,
	ShotId = 0,
	TrajectoryId = 0,
	TrajectoryReason = "NONE",
	ShotConfidence = 0,
	ShotUrgency = "NONE",
	ShotOriginPosition = nil,
	ShotDistanceClass = "UNKNOWN",
	StableInterceptX = nil,
	StableInterceptY = nil,
	StableInterceptTime = nil,
	StableInterceptShotId = -1,
	DiveCandidateShotId = -1,
	DiveCandidateSide = 0,
	DiveCandidateFrames = 0,
	DivedTrajectoryId = -1,
	LastKick = -100,
	LastControlRepair = -100,
	HookCount = 0,
	ControlHookCalls = 0,
	LastControlHookRead = -100,
	MovementDriver = "WAIT",
	LastMovementHealthPosition = nil,
	LastMovementHealthCheck = -100,
	LastMovementRepair = -100,
	MovementRepairs = 0,
	HumanoidFallbackUntil = 0,
	InputPolarity = 1,
	WrongDirectionSamples = 0,
	CorrectDirectionSamples = 0,
	InputCalibrationState = "PENDING",
	PositionSource = nil,
	PositionLastValue = nil,
	PositionLastTime = 0,
	PositionInvalidSamples = 0,
	PositionFault = "NONE",
	DefendedGoalObject = nil,
	DefendedGoalName = nil,
	DefendedZoneObject = nil,
	GoalLockSince = 0,
	ReferenceGoalObject = nil,
	ReferenceWorldPosition = nil,
	ReferenceDepth = nil,
	MovementFaultUntil = 0,
	LastDiagnostics = -100,
	HoldingBall = false,
	NativeGrab = false,
	GrabSignal = "NONE",
	GrabFSM = "ARMED",
	LastGrab = -100,
	LastGrabAttempt = -100,
	LastBallNear = -100,
	Diving = false,
	DiveToken = 0,
	DiveStartTime = -100,
	DiveMinimumEndAt = 0,
	DiveMaximumEndAt = 0,
	DiveStillSince = nil,
	DiveFirstMotionAt = nil,
	DiveMotionSamples = {},
	DivePreviousBallVelocity = nil,
	DiveContactDetected = false,
	DiveContactKind = "NONE",
	DiveContactPosition = nil,
	DiveExpectedImpactAt = 0,
	LastDeflectionAt = -100,
	DiveContactTime = CONFIG.DefaultDiveContactTime,
	DiveContactLearnedToken = -1,
	LastDive = -100,
	ContactWindowUntil = 0,
	GetUpEarliest = 0,
	GetUpDeadline = 0,
	RecoveryRequired = false,
	RecoveryReason = "NONE",
	InputLearningPausedUntil = 0,
	ReboundUntil = 0,
	DiveStart = nil,
	DiveMaximum = 0,
	DiveDirectionName = "NONE",
	DiveTimingModel = "MOTION",
	DiveCommandedTier = nil,
	DiveVerticalInputPolarity = 1,
	DiveStartHitboxOffsetY = nil,
	DiveHitboxPeakDelta = -math.huge,
	DiveHitboxTroughDelta = math.huge,
	DiveHitboxBinsThisDive = {},
	DiveHitboxSampleCount = 0,
	DiveHitboxCalibrationToken = -1,
	DiveReachLeft = CONFIG.DefaultDiveReach,
	DiveReachRight = CONFIG.DefaultDiveReach,
	DiveProfiles = {
		LEFT_LOW = {reach = CONFIG.DefaultDiveReach * 0.88, contact = CONFIG.DefaultDiveContactTime, windup = 0.09, t25 = 0.09, t50 = 0.18, t75 = 0.28, t100 = 0.40, samples = 0, hitboxTimeline = {}, hitboxDives = 0, hitboxBinCount = 0},
		LEFT_MID = {reach = CONFIG.DefaultDiveReach, contact = CONFIG.DefaultDiveContactTime, windup = 0.09, t25 = 0.09, t50 = 0.18, t75 = 0.28, t100 = 0.40, samples = 0, hitboxTimeline = {}, hitboxDives = 0, hitboxBinCount = 0},
		LEFT_HIGH = {reach = CONFIG.DefaultDiveReach * 0.86, contact = CONFIG.DefaultDiveContactTime + 0.05, windup = 0.10, t25 = 0.10, t50 = 0.20, t75 = 0.31, t100 = 0.44, samples = 0, hitboxTimeline = {}, hitboxDives = 0, hitboxBinCount = 0},
		RIGHT_LOW = {reach = CONFIG.DefaultDiveReach * 0.88, contact = CONFIG.DefaultDiveContactTime, windup = 0.09, t25 = 0.09, t50 = 0.18, t75 = 0.28, t100 = 0.40, samples = 0, hitboxTimeline = {}, hitboxDives = 0, hitboxBinCount = 0},
		RIGHT_MID = {reach = CONFIG.DefaultDiveReach, contact = CONFIG.DefaultDiveContactTime, windup = 0.09, t25 = 0.09, t50 = 0.18, t75 = 0.28, t100 = 0.40, samples = 0, hitboxTimeline = {}, hitboxDives = 0, hitboxBinCount = 0},
		RIGHT_HIGH = {reach = CONFIG.DefaultDiveReach * 0.86, contact = CONFIG.DefaultDiveContactTime + 0.05, windup = 0.10, t25 = 0.10, t50 = 0.20, t75 = 0.31, t100 = 0.44, samples = 0, hitboxTimeline = {}, hitboxDives = 0, hitboxBinCount = 0},
	},
	ActiveDiveProfile = nil,
	RunSpeed = CONFIG.DefaultRunSpeed,
	RunAcceleration = CONFIG.DefaultRunAcceleration,
	LastKeeperPosition = nil,
	LastKeeperVelocity = Vector3.zero,
	LastKeeperSample = 0,
	Possessor = nil,
	PossessorUntil = 0,
	PossessorConfidence = 0,
	PossessorStableSince = 0,
	PossessorStablePlayer = nil,
	AnticipationX = nil,
	AnticipationPlayer = nil,
	AnticipationShooterX = nil,
	AnticipationWeight = 0,
	AnticipationActive = false,
	IntentPlayer = nil,
	IntentState = "IDLE",
	IntentConfidence = 0,
	IntentAimX = nil,
	IntentAimY = nil,
	IntentEvidence = "NONE",
	IntentStableSince = 0,
	IntentUntil = 0,
	IntentReleasePlayer = nil,
	IntentReleaseUntil = 0,
	VirtualGateShotId = -1,
	VirtualGateGoal = nil,
	VirtualGateLastDepth = nil,
	VirtualGateLastTime = nil,
	VirtualGateLastCrossDepth = nil,
	VirtualGateLastCrossTime = nil,
	VirtualGateCrossCount = 0,
	VirtualGateSpeed = 0,
	VirtualGateConfidence = 0,
	VirtualGateLastEvent = -100,
	PredictionConfidence = 0,
	PredictionUncertainty = 1,
	PredictionModelSince = 0,
	PredictionLastModel = "CV",
	RunETA = math.huge,
	DiveETA = math.huge,
	BallETA = math.huge,
	SaveMethod = "WAIT",
	GoalMode = "SEARCHING",
	BallInRange = false,
	RunMargin = -math.huge,
	DiveMargin = -math.huge,
	LoggedOutcomeShotId = -1,
	PreparedGrabUntil = 0,
	PreparedGrabETA = math.huge,
	PredictionBias = Vector3.zero,
	OutcomeBiasSamples = 0,
	PredictedGoalImpact = nil,
	BallSourceChanged = false,
	PredictionCorridorMinX = nil,
	PredictionCorridorMaxX = nil,
	PredictionCorridorMinY = nil,
	PredictionCorridorMaxY = nil,
}

local Tracker = {
	Ball = nil,
	LastDiscovery = -100,
	CandidateMemory = setmetatable({}, {__mode = "k"}),
	History = {},
	Measurements = {},
	Position = nil,
	MeasurementPosition = nil,
	FilterPosition = nil,
	FilterVelocity = Vector3.zero,
	FilterAcceleration = Vector3.zero,
	MeasurementAge = 0,
	NetworkPing = 0,
	CurveAcceleration = Vector3.zero,
	CurveDirection = Vector3.zero,
	CurveFrames = 0,
	CurveConfirmed = false,
	Dataset = nil,
	DatasetModel = nil,
	PhysicsBall = nil,
	Velocity = Vector3.zero,
	RawVelocity = Vector3.zero,
	Acceleration = Vector3.zero,
	CurveVelocity = Vector3.zero,
	UpForceVelocity = Vector3.zero,
	LastTime = 0,
	Grounded = false,
	GroundY = nil,
	GroundDeceleration = CONFIG.DefaultGroundDeceleration,
	Model = "CV",
	ModelErrors = {CV = 1, GRAVITY = 1, ACCEL = 1, CURVE = 1, GROUND = 1},
	LastPredictionState = nil,
	LastAcceptedVelocity = Vector3.zero,
	LastBounce = -100,
	LastFilterTime = 0,
	CurvePredictionCacheStamp = -1,
	CurvePredictionCache = nil,
}

local Goals = {}

--==============================================================
-- UTILITIES
--==============================================================

local function clamp01(value) return math.clamp(value, 0, 1) end
local function sign(value) return value < 0 and -1 or (value > 0 and 1 or 0) end
local function horizontal(value) return Vector3.new(value.X, 0, value.Z) end
local function safeUnit(value) return value.Magnitude > 0.001 and value.Unit or Vector3.zero end
local function lerp(a, b, alpha) return a + (b - a) * alpha end

local function setSavePhase(phase, event)
	if Runtime.SavePhase ~= phase then
		Runtime.SavePhase = phase
		Runtime.SavePhaseSince = os.clock()
	end
	if event then Runtime.Event = event end
end

local function angleBetween(a, b)
	if a.Magnitude < 0.01 or b.Magnitude < 0.01 then return 0 end
	return math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1)))
end

local function safeRequire(module)
	if not module or not module:IsA("ModuleScript") then return nil end
	local ok, result = pcall(require, module)
	if ok then return result end
	warn("[GK V23 REQUIRE]", module:GetFullName(), result)
	return nil
end

local function getCharacterModel(player)
	player = player or LocalPlayer
	if Runtime.Wrapper and typeof(Runtime.Wrapper.GetPlayerCharacter) == "function" then
		local ok, character = pcall(Runtime.Wrapper.GetPlayerCharacter, player)
		if ok and typeof(character) == "Instance" then return character end
	end
	if player.Character then return player.Character end
	local folder = Workspace:FindFirstChild("CharacterFolder")
	if not folder then return nil end
	local exact = folder:FindFirstChild(tostring(player.UserId)) or folder:FindFirstChild(player.Name)
	if exact then return exact end
	for _, candidate in ipairs(folder:GetChildren()) do
		if candidate:GetAttribute("UserId") == player.UserId
			or candidate:GetAttribute("PlayerId") == player.UserId
			or candidate:GetAttribute("OwnerUserId") == player.UserId then
			return candidate
		end
	end
	return nil
end

local function getRoot(player)
	player = player or LocalPlayer
	local character = getCharacterModel(player)
	if not character then return nil end
	if character:IsA("BasePart") then return character end
	return character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChildWhichIsA("BasePart", true)
end

local function getTrackedPlayerRoot(player)
	if not player then return nil end
	local root = getRoot(player)
	if root then return root end
	local function partFromObject(object)
		if not object then return nil end
		if object:IsA("BasePart") then return object end
		if object:IsA("Model") then return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true) end
		return object:FindFirstChildWhichIsA("BasePart", true)
	end
	local folder = Workspace:FindFirstChild("CharacterFolder")
	if folder then
		local exact = partFromObject(folder:FindFirstChild(player.Name))
		if exact then return exact end
		for _, candidate in ipairs(folder:GetChildren()) do
			if candidate:GetAttribute("UserId") == player.UserId
				or candidate:GetAttribute("PlayerId") == player.UserId
				or candidate:GetAttribute("OwnerUserId") == player.UserId then
				local part = partFromObject(candidate)
				if part then return part end
			end
		end
	end
	local hitboxes = Workspace:FindFirstChild("PlayerHitboxes")
	if hitboxes then
		for _, candidate in ipairs(hitboxes:GetChildren()) do
			if candidate.Name == player.Name or candidate:GetAttribute("UserId") == player.UserId then
				local part = partFromObject(candidate)
				if part then return part end
			end
		end
	end
	return nil
end

local function ownedPartFromFolder(folder)
	if not folder then return nil end
	local object = folder:FindFirstChild(tostring(LocalPlayer.UserId)) or folder:FindFirstChild(LocalPlayer.Name)
	local function asPart(candidate)
		if not candidate then return nil end
		if candidate:IsA("BasePart") then return candidate end
		if candidate:IsA("Model") then return candidate.PrimaryPart or candidate:FindFirstChildWhichIsA("BasePart", true) end
		return nil
	end
	local exact = asPart(object)
	if exact then return exact end
	for _, candidate in ipairs(folder:GetChildren()) do
		if candidate:GetAttribute("UserId") == LocalPlayer.UserId
			or candidate:GetAttribute("PlayerId") == LocalPlayer.UserId
			or candidate:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
			local part = asPart(candidate)
			if part then return part end
		end
	end
	return nil
end

local function readKeeperPositionSource(source)
	if source == "CHICKYNOID" then
		if Runtime.Wrapper and typeof(Runtime.Wrapper.GetPlayerPosition) == "function" then
			local ok, value = pcall(Runtime.Wrapper.GetPlayerPosition, LocalPlayer)
			if ok and typeof(value) == "Vector3" then return value end
		end
	elseif source == "ROOT" then
		local root = getRoot()
		if root then return root.Position end
	elseif source == "CHARACTER_FOLDER" then
		local part = ownedPartFromFolder(Workspace:FindFirstChild("CharacterFolder"))
		if part then return part.Position end
	elseif source == "PLAYER_HITBOX" then
		local part = ownedPartFromFolder(Workspace:FindFirstChild("PlayerHitboxes"))
		if part then return part.Position end
	end
	return nil
end

local function resetKeeperPositionSource()
	Runtime.PositionSource = nil
	Runtime.PositionLastValue = nil
	Runtime.PositionLastTime = 0
	Runtime.PositionInvalidSamples = 0
	Runtime.PositionFault = "NONE"
end

local function getKeeperPosition()
	if Runtime.PositionInvalidSamples >= CONFIG.PositionSourceMaximumFailures then
		Runtime.PositionFault = "POSITION SOURCE FAILED"
		return nil
	end
	if not Runtime.PositionSource then
		for _, source in ipairs({"CHICKYNOID", "ROOT", "CHARACTER_FOLDER", "PLAYER_HITBOX"}) do
			local value = readKeeperPositionSource(source)
			if value then
				Runtime.PositionSource = source
				Runtime.PositionLastValue = value
				Runtime.PositionLastTime = os.clock()
				Runtime.PositionFault = "NONE"
				return value
			end
		end
		Runtime.PositionFault = "NO POSITION SOURCE"
		return nil
	end

	local value = readKeeperPositionSource(Runtime.PositionSource)
	if not value then
		Runtime.PositionInvalidSamples += 1
		Runtime.PositionFault = Runtime.PositionInvalidSamples >= CONFIG.PositionSourceMaximumFailures
			and "POSITION SOURCE FAILED" or "POSITION SOURCE LOST"
		return nil
	end
	local now = os.clock()
	if Runtime.PositionLastValue and Runtime.PositionLastTime > 0 then
		local dt = math.max(0, now - Runtime.PositionLastTime)
		local maximumTravel = CONFIG.PositionJumpTolerance + CONFIG.PositionMaximumSpeed * dt
		if (value - Runtime.PositionLastValue).Magnitude > maximumTravel then
			Runtime.PositionInvalidSamples += 1
			Runtime.PositionFault = Runtime.PositionInvalidSamples >= CONFIG.PositionSourceMaximumFailures
				and "POSITION SOURCE FAILED" or "POSITION JUMP REJECTED"
			Runtime.Event = Runtime.PositionFault
			return nil
		end
	end
	Runtime.PositionLastValue = value
	Runtime.PositionLastTime = now
	Runtime.PositionInvalidSamples = 0
	Runtime.PositionFault = "NONE"
	return value
end

local function getKeeperVelocity()
	if Runtime.Wrapper and typeof(Runtime.Wrapper.GetVelocity) == "function" then
		local ok, value = pcall(Runtime.Wrapper.GetVelocity)
		if ok and typeof(value) == "Vector3" then return value end
	end
	local root = getRoot()
	return root and root.AssemblyLinearVelocity or Vector3.zero
end

local function getGoalieGrabHitbox()
	local character = getCharacterModel(LocalPlayer)
	local direct = character and character:FindFirstChild("GoalieGrab", true)
	if direct and direct:IsA("BasePart") then return direct end
	local hitboxes = Workspace:FindFirstChild("PlayerHitboxes")
	if hitboxes then
		local exact = hitboxes:FindFirstChild(tostring(LocalPlayer.UserId)) or hitboxes:FindFirstChild(LocalPlayer.Name)
		local exactGrab = exact and exact:FindFirstChild("GoalieGrab", true)
		if exactGrab and exactGrab:IsA("BasePart") then return exactGrab end
		for _, candidate in ipairs(hitboxes:GetChildren()) do
			if candidate.Name == LocalPlayer.Name
				or candidate:GetAttribute("UserId") == LocalPlayer.UserId
				or candidate:GetAttribute("PlayerId") == LocalPlayer.UserId then
				local grab = candidate:FindFirstChild("GoalieGrab", true)
				if grab and grab:IsA("BasePart") then return grab end
			end
		end
	end
	return nil
end

local function distanceToOrientedBox(point, part)
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size * 0.5
	local closest = Vector3.new(
		math.clamp(localPoint.X, -half.X, half.X),
		math.clamp(localPoint.Y, -half.Y, half.Y),
		math.clamp(localPoint.Z, -half.Z, half.Z)
	)
	return (localPoint - closest).Magnitude
end

local function orientedBoxExtent(part, axis)
	local half = part.Size * 0.5
	local frame = part.CFrame
	return math.abs(frame.RightVector:Dot(axis)) * half.X
		+ math.abs(frame.UpVector:Dot(axis)) * half.Y
		+ math.abs(frame.LookVector:Dot(axis)) * half.Z
end

local function getTrackedBallRadius()
	local ball = Tracker.PhysicsBall or Tracker.Ball
	if ball and ball:IsA("BasePart") then
		return math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) * 0.5
	end
	return CONFIG.BallRadius
end

local function learnDiveContact(now, kind)
	if Runtime.DiveContactLearnedToken == Runtime.DiveToken or not Runtime.ActiveDiveProfile then return end
	local elapsed = now - Runtime.DiveStartTime
	if elapsed < CONFIG.MinimumDiveContactTime
		or elapsed > CONFIG.DiveMaximumActiveTime + CONFIG.DiveContactWindowTime + CONFIG.GrabConfirmWindow then
		return
	end
	local measured = math.clamp(elapsed, CONFIG.MinimumDiveContactTime, CONFIG.MaximumDiveContactTime)
	Runtime.DiveContactTime = lerp(Runtime.DiveContactTime, measured, CONFIG.DiveContactLearnAlpha)
	local profile = Runtime.DiveProfiles[Runtime.ActiveDiveProfile]
	if profile then
		profile.contact = lerp(profile.contact, measured, CONFIG.DiveContactLearnAlpha)
		profile.samples += 1
	end
	Runtime.DiveContactLearnedToken = Runtime.DiveToken
	Runtime.Event = string.format("%s CONTACT LEARNED %.3f", kind or "DIVE", Runtime.DiveContactTime)
end

--==============================================================
-- MODULES + SELBSTHEILENDER V16 CONTROLMODULE-HOOK
--==============================================================

local HookedControls = setmetatable({}, {__mode = "k"})

local function hookControl(control)
	if typeof(control) ~= "table" or typeof(control.GetMoveVector) ~= "function" then return false end
	local oldRecord = HookedControls[control]
	if oldRecord and control.GetMoveVector == oldRecord.replacement then return true end
	local original = control.GetMoveVector
	local replacement = function(self, ...)
		Runtime.ControlHookCalls += 1
		Runtime.LastControlHookRead = os.clock()
		if Runtime.ForcedMoveVector ~= nil then return Runtime.ForcedMoveVector end
		return original(self, ...)
	end
	local ok = pcall(function() control.GetMoveVector = replacement end)
	if ok then HookedControls[control] = {original = original, replacement = replacement} end
	return ok
end

local function resolveModulesAndHooks()
	local modules = ReplicatedStorage:FindFirstChild("ModuleScripts")
	if modules then
		if not Runtime.Movement or typeof(Runtime.Movement.InputBegan) ~= "function" then
			Runtime.Movement = safeRequire(modules:FindFirstChild("Movement", true))
		end
		if not Runtime.Wrapper then Runtime.Wrapper = safeRequire(modules:FindFirstChild("ChickynoidWrapper", true)) end
		if not Runtime.Auxillary then Runtime.Auxillary = safeRequire(modules:FindFirstChild("Auxillary", true)) end
		if not Runtime.ClientBall then Runtime.ClientBall = safeRequire(modules:FindFirstChild("ClientBall", true)) end
	end
	local active = 0
	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local playerModuleScript = playerScripts and playerScripts:FindFirstChild("PlayerModule")
	if playerModuleScript then
		local direct = playerModuleScript:FindFirstChild("ControlModule", true)
		if direct and hookControl(safeRequire(direct)) then active += 1 end
		local playerModule = safeRequire(playerModuleScript)
		if playerModule and typeof(playerModule.GetControls) == "function" then
			local ok, controls = pcall(function() return playerModule:GetControls() end)
			if ok and hookControl(controls) then active += 1 end
		end
	end
	Runtime.HookCount = active
	local root = getRoot()
	Runtime.ChickynoidDetected = Runtime.Wrapper ~= nil or (root and root.Anchored == true) or false
	Runtime.MovementDriver = active > 0 and "CONTROLMODULE" or (Runtime.ChickynoidDetected and "CHICKYNOID HOOK WAIT" or "HUMANOID FALLBACK")
end

--==============================================================
-- ECHTE TORGEOMETRIE AUS Workspace.Pitch.Hitboxes.Goals
--==============================================================

local function collectParts(object)
	local parts = {}
	if object:IsA("BasePart") then table.insert(parts, object) end
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("BasePart") then table.insert(parts, descendant) end
	end
	return parts
end

local function choosePostPair(parts)
	local vertical = {}
	for _, part in ipairs(parts) do
		local horizontalSize = math.max(part.Size.X, part.Size.Z, 0.01)
		local aspect = part.Size.Y / horizontalSize
		if part.Size.Y >= CONFIG.MinimumPostHeight and aspect >= CONFIG.MinimumPostAspect then
			table.insert(vertical, part)
		end
	end
	local first, second, bestScore = nil, nil, -math.huge
	for i = 1, #vertical do
		for j = i + 1, #vertical do
			local distance = horizontal(vertical[j].Position - vertical[i].Position).Magnitude
			if distance >= CONFIG.MinimumGoalWidth then
				local score = distance + math.min(vertical[i].Size.Y, vertical[j].Size.Y) * 0.35
				if score > bestScore then first, second, bestScore = vertical[i], vertical[j], score end
			end
		end
	end
	return first, second
end

local function buildGoal(object)
	local parts = collectParts(object)
	if #parts == 0 then return nil end
	local points = {}
	local bottomY, topY = math.huge, -math.huge
	for _, part in ipairs(parts) do
		bottomY = math.min(bottomY, part.Position.Y - part.Size.Y * 0.5)
		topY = math.max(topY, part.Position.Y + part.Size.Y * 0.5)
		local half = part.Size * 0.5
		for x = -1, 1, 2 do
			for y = -1, 1, 2 do
				for z = -1, 1, 2 do
					table.insert(points, part.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z)))
				end
			end
		end
	end
	local sum = Vector3.zero
	for _, point in ipairs(points) do sum += point end
	local approximateCenter = sum / math.max(#points, 1)
	local postA, postB = choosePostPair(parts)
	return {
		name = object.Name,
		object = object,
		center = Vector3.new(approximateCenter.X, bottomY, approximateCenter.Z),
		rawCenter = Vector3.new(approximateCenter.X, bottomY, approximateCenter.Z),
		points = points,
		postA = postA,
		postB = postB,
		right = nil,
		field = nil,
		up = Vector3.yAxis,
		halfWidth = 0,
		bottomY = bottomY,
		topY = topY,
	}
end

local function finishGoalDimensions(goal)
	goal.homeDepth = math.clamp(goal.halfWidth * CONFIG.HomeDepthWidthRatio, CONFIG.HomeDepthMin, CONFIG.HomeDepthMax)
	goal.maximumDepth = math.clamp(goal.halfWidth * CONFIG.MaximumDepthWidthRatio, CONFIG.MaximumDepthMin, CONFIG.MaximumDepthMax)
	goal.dangerDepth = goal.halfWidth * CONFIG.DangerDepthWidthRatio
	return goal
end

local function applyGoalZoneBounds(goal, zone)
	goal.zoneMinX, goal.zoneMaxX = nil, nil
	goal.zoneMinDepth, goal.zoneMaxDepth = nil, nil
	if not zone or not zone:IsA("BasePart") or not goal.right or not goal.field then return end
	local half = zone.Size * 0.5
	local minX, maxX = math.huge, -math.huge
	local minDepth, maxDepth = math.huge, -math.huge
	for _, x in ipairs({-1, 1}) do
		for _, y in ipairs({-1, 1}) do
			for _, z in ipairs({-1, 1}) do
				local point = zone.CFrame:PointToWorldSpace(Vector3.new(half.X * x, half.Y * y, half.Z * z))
				local offset = point - goal.center
				local lateral = offset:Dot(goal.right)
				local depth = offset:Dot(goal.field)
				minX, maxX = math.min(minX, lateral), math.max(maxX, lateral)
				minDepth, maxDepth = math.min(minDepth, depth), math.max(maxDepth, depth)
			end
		end
	end
	if minX < maxX and minDepth < maxDepth then
		goal.zoneMinX, goal.zoneMaxX = minX, maxX
		goal.zoneMinDepth, goal.zoneMaxDepth = minDepth, maxDepth
	end
end

local function makeFallbackGoals()
	local function make(name, z, field)
		local right = safeUnit(field:Cross(Vector3.yAxis))
		return finishGoalDimensions({
			name = name,
			object = nil,
			center = Vector3.new(CONFIG.FallbackGoalCenterX, CONFIG.FallbackGoalBottomY, z),
			rawCenter = Vector3.new(CONFIG.FallbackGoalCenterX, CONFIG.FallbackGoalBottomY, z),
			points = {},
			postA = nil,
			postB = nil,
			right = right,
			field = field,
			up = Vector3.yAxis,
			halfWidth = CONFIG.FallbackGoalHalfWidth,
			bottomY = CONFIG.FallbackGoalBottomY,
			topY = CONFIG.FallbackGoalTopY,
			fallback = true,
		})
	end
	return {
		make("POSITIVE / V20 FALLBACK", CONFIG.FallbackPositiveGoalZ, Vector3.new(0, 0, -1)),
		make("NEGATIVE / V20 FALLBACK", CONFIG.FallbackNegativeGoalZ, Vector3.new(0, 0, 1)),
	}
end

local function assignZonesSpatially(goals, zones)
	for _, goal in ipairs(goals) do goal.zone = nil end
	if #goals == 0 or #zones < #goals then return false end
	local bestCost, bestAssignment = math.huge, nil
	local used, assignment = {}, {}
	local function search(goalIndex, cost)
		if cost >= bestCost then return end
		if goalIndex > #goals then
			bestCost = cost
			bestAssignment = table.clone(assignment)
			return
		end
		for zoneIndex, zone in ipairs(zones) do
			if not used[zoneIndex] then
				used[zoneIndex] = true
				assignment[goalIndex] = zone
				local distance = horizontal(zone.Position - goals[goalIndex].rawCenter).Magnitude
				search(goalIndex + 1, cost + distance)
				assignment[goalIndex] = nil
				used[zoneIndex] = nil
			end
		end
	end
	-- Die Live-Struktur besitzt normalerweise genau zwei Tore und zwei Zonen.
	-- Das Limit verhindert eine unnötig große Permutationssuche auf fremden Maps.
	if #goals <= 4 and #zones <= 6 then search(1, 0) end
	if not bestAssignment then return false end
	for index, goal in ipairs(goals) do
		local zone = bestAssignment[index]
		local assignedDistance = horizontal(zone.Position - goal.rawCenter).Magnitude
		for otherIndex, otherGoal in ipairs(goals) do
			if otherIndex ~= index then
				local otherDistance = horizontal(zone.Position - otherGoal.rawCenter).Magnitude
				if otherDistance + 1 < assignedDistance then
					for _, resetGoal in ipairs(goals) do resetGoal.zone = nil end
					return false
				end
			end
		end
		goal.zone = zone
	end
	return true
end

local function refreshGoals()
	local pitch = Workspace:FindFirstChild("Pitch")
	local hitboxes = (pitch and pitch:FindFirstChild("Hitboxes")) or Workspace:FindFirstChild("Hitboxes")
	local folder = hitboxes and hitboxes:FindFirstChild("Goals")
	local zoneFolder = hitboxes and hitboxes:FindFirstChild("GoalkeeperZones")
	local goalkeeperZones = zoneFolder and collectParts(zoneFolder) or {}
	local found = {}
	if folder then
		for _, object in ipairs(folder:GetChildren()) do
			local goal = buildGoal(object)
			if goal then table.insert(found, goal) end
		end
	end
	local liveZoneGeometry = folder ~= nil and #found >= 2 and #goalkeeperZones >= 2
	if #found >= 2 then
		local zonesAssigned = assignZonesSpatially(found, goalkeeperZones)
		for index, goal in ipairs(found) do
			local exactIndex = tonumber(string.match(goal.name, "^Goal(%d+)$"))
			goal.teamIndex = exactIndex
			goal.exact = exactIndex ~= nil
			local closest, closestDistance = nil, math.huge
			for otherIndex, other in ipairs(found) do
				if otherIndex ~= index then
					local distance = horizontal(other.rawCenter - goal.rawCenter).Magnitude
					if distance < closestDistance then closest, closestDistance = other, distance end
				end
			end
			goal.field = closest and safeUnit(horizontal(closest.rawCenter - goal.rawCenter)) or nil
			-- Die passende GoalkeeperZone liegt vor dem Tor im Spielfeld. Diese
			-- bekannte Geometrie entscheidet daher endgültig über das Vorzeichen
			-- der Tiefenachse. So kann Goal1/Goal2 niemals spiegelverkehrt laufen.
			if goal.field and goal.zone then
				local towardZone = horizontal(goal.zone.Position - goal.rawCenter)
				if towardZone.Magnitude > 1 and towardZone:Dot(goal.field) < 0 then
					goal.field = -goal.field
				end
			end
			if goal.field then
				-- Orthonormale Torbasis: RIGHT steht immer exakt quer zur
				-- Verbindung beider Tore, unabhängig von Welt-X/Z.
				goal.right = safeUnit(goal.field:Cross(Vector3.yAxis))
				local minRight, maxRight, front = math.huge, -math.huge, -math.huge
				for _, point in ipairs(goal.points) do
					local offset = point - goal.center
					local lateral = offset:Dot(goal.right)
					local depth = offset:Dot(goal.field)
					minRight = math.min(minRight, lateral)
					maxRight = math.max(maxRight, lateral)
					front = math.max(front, depth)
				end
				local centerLateral = (minRight + maxRight) * 0.5
				goal.center = goal.center + goal.right * centerLateral + goal.field * front
				goal.halfWidth = (maxRight - minRight) * 0.5
				-- Wenn echte Pfosten vorhanden sind, verhindern sie, dass eine
				-- breite Netz-/Triggerbox die Torbreite künstlich vergrößert.
				if goal.postA and goal.postB then
					local postWidth = math.abs((goal.postB.Position - goal.postA.Position):Dot(goal.right)) * 0.5
					if postWidth >= CONFIG.MinimumGoalWidth * 0.5 then goal.halfWidth = math.min(goal.halfWidth, postWidth) end
				end
			end
			finishGoalDimensions(goal)
			applyGoalZoneBounds(goal, goal.zone)
		end
		local valid = {}
		for _, goal in ipairs(found) do
			if goal.field and goal.right and goal.halfWidth * 2 >= CONFIG.MinimumGoalWidth
				and (not liveZoneGeometry or goal.zone) then
				table.insert(valid, goal)
			end
		end
		if #valid >= 2 then
			table.sort(valid, function(a, b)
				return (a.teamIndex or math.huge) < (b.teamIndex or math.huge)
			end)
			Goals = valid
			Runtime.CalibrationOK = true
			local exact = valid[1].exact and valid[2].exact and zonesAssigned and valid[1].zone and valid[2].zone
			local mode = exact and "EXACT GOAL1/2" or "LIVE PITCH"
			if Runtime.GoalMode ~= mode then Runtime.Event = exact and "EXACT GOALS + ZONES LOCKED" or "PITCH GOALS + GK ZONES LIVE" end
			Runtime.GoalMode = mode
			return
		end
	end
	if liveZoneGeometry then
		Goals = {}
		Runtime.CalibrationOK = false
		Runtime.GoalMode = "FAILED"
		Runtime.Event = "LIVE GOAL/ZONE PAIRING FAILED"
		return
	end
	if CONFIG.EnableV20GoalFallback then
		Goals = makeFallbackGoals()
		Runtime.CalibrationOK = true
		if Runtime.GoalMode ~= "V20 FALLBACK" then Runtime.Event = "GOAL FALLBACK ACTIVE" end
		Runtime.GoalMode = "V20 FALLBACK"
	else
		Goals = {}
		Runtime.CalibrationOK = false
		Runtime.GoalMode = "FAILED"
		Runtime.Event = "GOAL CALIBRATION FAILED"
	end
end

local function goalToLocal(goal, worldPosition)
	local offset = worldPosition - goal.center
	return Vector3.new(offset:Dot(goal.right), worldPosition.Y - goal.bottomY, offset:Dot(goal.field))
end

local function goalToWorld(goal, lateral, depth, worldY)
	return goal.center + goal.right * lateral + goal.field * depth + Vector3.new(0, worldY - goal.bottomY, 0)
end

local function pointInsideGoalZone(goal, worldPosition, inset)
	if not goal or not goal.zone or not goal.zone.Parent or not worldPosition then return false end
	local localPosition = goal.zone.CFrame:PointToObjectSpace(worldPosition)
	local half = goal.zone.Size * 0.5
	inset = math.max(0, inset or 0)
	return math.abs(localPosition.X) <= math.max(0, half.X - inset)
		and math.abs(localPosition.Z) <= math.max(0, half.Z - inset)
end

local function resetDefendedGoalLock(reason)
	Runtime.DefendedGoal = nil
	Runtime.DefendedGoalObject = nil
	Runtime.DefendedGoalName = nil
	Runtime.DefendedZoneObject = nil
	Runtime.GoalLockSince = 0
	Runtime.ReferenceGoalObject = nil
	Runtime.ReferenceWorldPosition = nil
	Runtime.ReferenceDepth = nil
	if reason then Runtime.Event = reason end
end

local function lockedGoalFromCurrentCalibration()
	if not Runtime.DefendedGoalName and not Runtime.DefendedGoalObject then return nil end
	for _, goal in ipairs(Goals) do
		local sameObject = Runtime.DefendedGoalObject and goal.object == Runtime.DefendedGoalObject
		local sameFallback = not Runtime.DefendedGoalObject and goal.name == Runtime.DefendedGoalName
		local sameZone = Runtime.DefendedZoneObject and goal.zone == Runtime.DefendedZoneObject
		if sameObject or sameFallback or sameZone then return goal end
	end
	return nil
end

local function getDefendedGoal(keeperPosition)
	local locked = lockedGoalFromCurrentCalibration()
	if locked then
		Runtime.DefendedGoal = locked
		return locked
	end
	-- Ein bereits vorhandener Lock darf niemals still auf das andere Tor fallen.
	-- Ist sein Objekt verschwunden, muss RECALL/Respawn neu kalibrieren.
	if Runtime.DefendedGoalName or Runtime.DefendedGoalObject then
		Runtime.DefendedGoal = nil
		Runtime.Event = "LOCKED GOAL MISSING"
		return nil
	end

	local contained, containedDistance = nil, math.huge
	local nearest, nearestDistance, secondDistance = nil, math.huge, math.huge
	for _, goal in ipairs(Goals) do
		if goal.field then
			local distance = horizontal(goal.center - keeperPosition).Magnitude
			if distance < nearestDistance then
				secondDistance = nearestDistance
				nearest, nearestDistance = goal, distance
			elseif distance < secondDistance then
				secondDistance = distance
			end
			if pointInsideGoalZone(goal, keeperPosition, 0) and distance < containedDistance then
				contained, containedDistance = goal, distance
			end
		end
	end
	if not contained and secondDistance < math.huge
		and secondDistance - nearestDistance < CONFIG.GoalLockMinimumAdvantage then
		Runtime.Event = "AWAITING CLEAR GOAL SIDE"
		return nil
	end
	local selected = contained or nearest
	if not selected then return nil end
	Runtime.DefendedGoal = selected
	Runtime.DefendedGoalObject = selected.object
	Runtime.DefendedGoalName = selected.name
	Runtime.DefendedZoneObject = selected.zone
	Runtime.GoalLockSince = os.clock()
	Runtime.ReferenceGoalObject = selected.object or selected.name
	Runtime.ReferenceWorldPosition = keeperPosition
	Runtime.ReferenceDepth = goalToLocal(selected, keeperPosition).Z
	Runtime.Event = "GOAL LOCK " .. selected.name .. (selected.zone and (" / " .. selected.zone.Name) or "")
	return selected
end

local function validateReferenceFrame(goal, keeperPosition, now)
	local goalKey = goal.object or goal.name
	local depth = goalToLocal(goal, keeperPosition).Z
	if Runtime.ReferenceGoalObject and Runtime.ReferenceGoalObject ~= goalKey then
		Runtime.MovementFaultUntil = now + 1.0
		Runtime.Event = "REFERENCE GOAL CHANGED"
		return false
	end
	if Runtime.ReferenceWorldPosition and Runtime.ReferenceDepth then
		local worldTravel = horizontal(keeperPosition - Runtime.ReferenceWorldPosition).Magnitude
		local depthTravel = math.abs(depth - Runtime.ReferenceDepth)
		if depthTravel > worldTravel + CONFIG.ReferenceDepthTolerance then
			Runtime.ReferenceWorldPosition = keeperPosition
			Runtime.ReferenceDepth = depth
			Runtime.MovementFaultUntil = now + 1.0
			Runtime.Event = "REFERENCE FRAME JUMP"
			return false
		end
	end
	Runtime.ReferenceGoalObject = goalKey
	Runtime.ReferenceWorldPosition = keeperPosition
	Runtime.ReferenceDepth = depth
	return true
end

local function getGoalMovementBounds(goal, allowOutsidePosts, extraInset)
	local inset = CONFIG.ZoneBoundaryInset + (extraInset or 0)
	local padding = allowOutsidePosts and CONFIG.SaveOutsidePadding or -CONFIG.PostInsidePadding
	local lateralLimit = math.max(0.5, goal.halfWidth + padding)
	local minX, maxX = -lateralLimit, lateralLimit
	-- maximumDepth ist selbst eine Bewegungsgrenze. Der Keeper zielt bewusst
	-- etwas davor, damit sein Körper nicht erst an der unsichtbaren Linie stoppt.
	local minDepth = CONFIG.GoalLineMinimumDepth + math.min(0.35, inset * 0.35)
	local maxDepth = math.max(minDepth + 0.5, goal.maximumDepth - inset)
	if goal.zoneMinX and goal.zoneMaxX then
		local zoneMinX = math.max(minX, goal.zoneMinX + inset)
		local zoneMaxX = math.min(maxX, goal.zoneMaxX - inset)
		if zoneMinX <= zoneMaxX then minX, maxX = zoneMinX, zoneMaxX end
	end
	if goal.zoneMinDepth and goal.zoneMaxDepth then
		local zoneMinDepth = math.max(minDepth, goal.zoneMinDepth + inset)
		local zoneMaxDepth = math.min(maxDepth, goal.zoneMaxDepth - inset)
		if zoneMinDepth <= zoneMaxDepth then minDepth, maxDepth = zoneMinDepth, zoneMaxDepth end
	end
	return minX, maxX, minDepth, maxDepth
end

local function clampSafeTarget(goal, worldTarget, allowOutsidePosts, extraInset)
	local localTarget = goalToLocal(goal, worldTarget)
	local minX, maxX, minDepth, maxDepth = getGoalMovementBounds(goal, allowOutsidePosts, extraInset)
	local lateral = math.clamp(localTarget.X, minX, maxX)
	local depth = math.clamp(localTarget.Z, minDepth, maxDepth)
	local safeTarget = goalToWorld(goal, lateral, depth, worldTarget.Y)
	if goal.zone and goal.zone.Parent then
		local zoneLocal = goal.zone.CFrame:PointToObjectSpace(safeTarget)
		local half = goal.zone.Size * 0.5
		local inset = CONFIG.ZoneBoundaryInset + (extraInset or 0)
		zoneLocal = Vector3.new(
			math.clamp(zoneLocal.X, -math.max(0.25, half.X - inset), math.max(0.25, half.X - inset)),
			zoneLocal.Y,
			math.clamp(zoneLocal.Z, -math.max(0.25, half.Z - inset), math.max(0.25, half.Z - inset))
		)
		safeTarget = goal.zone.CFrame:PointToWorldSpace(zoneLocal)
	end
	return safeTarget
end

local function pointInsideKeeperEnvelope(goal, worldPoint, tolerance)
	if not goal or not worldPoint then return false end
	local localPoint = goalToLocal(goal, worldPoint)
	local minX, maxX, minDepth, maxDepth = getGoalMovementBounds(goal, true, 0)
	tolerance = tolerance or 0
	local insideTactical = localPoint.X >= minX - tolerance and localPoint.X <= maxX + tolerance
		and localPoint.Z >= minDepth - tolerance and localPoint.Z <= maxDepth + tolerance
	if not insideTactical then return false end
	if goal.zone and goal.zone.Parent then
		local zoneLocal = goal.zone.CFrame:PointToObjectSpace(worldPoint)
		local half = goal.zone.Size * 0.5
		return math.abs(zoneLocal.X) <= half.X + tolerance
			and math.abs(zoneLocal.Z) <= half.Z + tolerance
	end
	return true
end


for _, name in ipairs({
	"SpecialGKBotV16Movement", "SpecialGKBotV17Movement",
	"SpecialGKBotV20Movement", "SpecialGKBotV21Movement",
	"SpecialGKBotV22Movement", "SpecialGKBotV22Camera",
	"SpecialGKBotV23Movement", "SpecialGKBotV23Camera",
}) do
	pcall(function() RunService:UnbindFromRenderStep(name) end)
end

--==============================================================
-- MINIMALE EIN-FENSTER-GUI
--==============================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "DODO-DEVIL V1"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 999999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(300, 140)
Main.Position = UDim2.new(0, 18, 0.5, -70)
Main.BackgroundColor3 = COLORS.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 11)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(65, 70, 83)
stroke.Transparency = 0.25

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 34)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -44, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "DODO-DEVIL V1"
Title.TextColor3 = COLORS.TEXT
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(24, 24)
Minimize.Position = UDim2.new(1, -29, 0, 5)
Minimize.BackgroundColor3 = COLORS.BUTTON
Minimize.BorderSizePixel = 0
Minimize.Text = "–"
Minimize.TextColor3 = COLORS.TEXT
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 15
Minimize.Parent = Main
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 7)

local Buttons, Labels = {}, {}

local function addButton(id, text, x, width, color)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(width, 28)
	button.Position = UDim2.fromOffset(x, 36)
	button.BackgroundColor3 = color or COLORS.BUTTON
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.TEXT
	button.Font = Enum.Font.GothamBold
	button.TextSize = 9
	button.Parent = Main
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
	Buttons[id] = button
	return button
end

local function addLabel(id, text, y, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 18)
	label.Position = UDim2.fromOffset(10, y)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or COLORS.MUTED
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 9
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = Main
	Labels[id] = label
	return label
end

addButton("Bot", "BOT ON", 8, 67, COLORS.GREEN)
addButton("Grab", "GRAB ON", 79, 67, COLORS.ORANGE)
addButton("Dive", "DIVE ON", 150, 67, COLORS.GREEN)
addButton("Recalibrate", "RECAL", 221, 71, COLORS.BLUE)
addLabel("Status", "STARTING", 72, COLORS.TEXT)
addLabel("Target", "TARGET --", 94)
addLabel("Telemetry", "BALL --  |  ETA --  |  ZONE --", 116)

local Reopen = Instance.new("TextButton")
Reopen.Size = UDim2.fromOffset(44, 44)
Reopen.Position = Main.Position
Reopen.BackgroundColor3 = COLORS.BLUE
Reopen.BorderSizePixel = 0
Reopen.Text = "GK"
Reopen.TextColor3 = COLORS.TEXT
Reopen.Font = Enum.Font.GothamBold
Reopen.TextSize = 12
Reopen.Visible = false
Reopen.Parent = Gui
Instance.new("UICorner", Reopen).CornerRadius = UDim.new(0, 10)

Minimize.MouseButton1Click:Connect(function()
	Reopen.Position = Main.Position
	Main.Visible = false
	Reopen.Visible = true
end)

Reopen.MouseButton1Click:Connect(function()
	Main.Position = Reopen.Position
	Reopen.Visible = false
	Main.Visible = true
end)

do
	local dragging, startMouse, startFrame = false, nil, nil
	Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startMouse, startFrame = true, input.Position, Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startMouse
			Main.Position = startFrame + UDim2.fromOffset(delta.X, delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end

--==============================================================
-- BALL DISCOVERY: KONTINUITÄT STATT BLINDER ClientBall-PRIORITÄT
--==============================================================

local BallCandidates = setmetatable({}, {__mode = "k"})

local function ballNameBonus(name)
	local exact = CONFIG.BallNames[name]
	if exact then return exact end
	local lower = string.lower(name)
	for configured, score in pairs(CONFIG.BallNames) do
		if lower == string.lower(configured) then return score end
	end
	if string.find(lower, "ball", 1, true) then return 22 end
	return 0
end

local function ballCandidateIdentity(part)
	local score = ballNameBonus(part.Name)
	local root = part
	local ancestor = part.Parent
	local levels = 0
	while ancestor and ancestor ~= Workspace and levels < 5 do
		local bonus = ballNameBonus(ancestor.Name)
		if bonus > score then score, root = bonus - levels * 2, ancestor end
		if ancestor.Name == "Balls" then score += 38 end
		ancestor = ancestor.Parent
		levels += 1
	end
	return score, root
end

local function registerBallCandidate(object)
	if not object:IsA("BasePart") then return end
	local identity = ballCandidateIdentity(object)
	local largest = math.max(object.Size.X, object.Size.Y, object.Size.Z)
	-- Namensgleiche Models mit einer anders benannten Physik-Part werden jetzt
	-- erkannt; riesige Feld-/Spawn-Parts bleiben ausgeschlossen.
	if identity > 0 and largest >= 0.20 and largest <= 8 then BallCandidates[object] = true end
end

for _, object in ipairs(Workspace:GetDescendants()) do registerBallCandidate(object) end
Workspace.DescendantAdded:Connect(registerBallCandidate)
Workspace.DescendantRemoving:Connect(function(object) BallCandidates[object] = nil end)

local function candidateBaseScore(part)
	if not part:IsA("BasePart") or not part:IsDescendantOf(Workspace) then return -math.huge end
	local identity, root = ballCandidateIdentity(part)
	if identity <= 0 then return -math.huge end
	local score = identity
	if root and root ~= part and root:IsA("Model") and root.PrimaryPart == part then score += 18 end
	if not part.Anchored then score += 18 else score -= 90 end
	if not part.CanQuery then score -= 4 end
	if part.AssemblyLinearVelocity.Magnitude > 0.5 then score += 8 end
	if Tracker.Ball == part then score += 22 end
	if Tracker.Position and (part.Position - Tracker.Position).Magnitude <= CONFIG.BallContinuityDistance then score += 18 end
	local memory = Tracker.CandidateMemory[part]
	if memory and (part.Position - memory.position).Magnitude > 0.03 then score += 8 end
	Tracker.CandidateMemory[part] = {position = part.Position, time = os.clock()}
	return score
end

local function getExactGameBallRoot()
	local current = Workspace
	for _, name in ipairs(CONFIG.ExactBallPath) do
		current = current and current:FindFirstChild(name)
		if not current then return nil end
	end
	return current
end

local function discoverBall(force)
	local now = os.clock()
	if not force and Tracker.Ball and Tracker.Ball.Parent and now - Tracker.LastDiscovery < CONFIG.BallDiscoveryInterval then return Tracker.Ball end
	Tracker.LastDiscovery = now
	local best, bestScore = nil, -math.huge
	local currentScore = Tracker.Ball and Tracker.Ball.Parent and candidateBaseScore(Tracker.Ball) or -math.huge
	-- Die bekannte Spielstruktur wird zuerst bewertet. Damit wird bei mehreren
	-- dekorativen Kugeln/Hitboxen nicht versehentlich das falsche Objekt verfolgt.
	local exactRoot = getExactGameBallRoot()
	if exactRoot then
		local exactCandidates = {
			exactRoot:FindFirstChild("ClientBall"),
			exactRoot:FindFirstChild("ServerBall"),
			exactRoot:IsA("BasePart") and exactRoot or nil,
		}
		for index, candidate in ipairs(exactCandidates) do
			if candidate and candidate:IsA("BasePart") then
				local score = candidateBaseScore(candidate)
				if score > -math.huge then
					score += 420 - index * 5
					if score > bestScore then best, bestScore = candidate, score end
				end
			end
		end
	end
	for object in pairs(BallCandidates) do
		local score = candidateBaseScore(object)
		if score > bestScore then best, bestScore = object, score end
	end
	local activeTrajectoryLock = Tracker.Ball and Tracker.Ball.Parent and Tracker.Position
		and Tracker.Velocity.Magnitude >= CONFIG.BallTrajectoryLockMinimumSpeed
		and Runtime.TrajectoryId > 0
	if Tracker.Ball and Tracker.Ball.Parent and best ~= Tracker.Ball
		and (activeTrajectoryLock or bestScore < currentScore + CONFIG.BallSwitchMargin) then
		best = Tracker.Ball
	end
	if best ~= Tracker.Ball then
		local replacingTrackedBall = Tracker.Ball ~= nil
		Tracker.Ball = best
		Runtime.BallSourceChanged = replacingTrackedBall
		Runtime.ShotOriginPosition = nil
		Runtime.ShotDistanceClass = "UNKNOWN"
		Runtime.AnticipationX = nil
		Runtime.AnticipationPlayer = nil
		Runtime.AnticipationActive = false
		Runtime.IntentPlayer = nil
		Runtime.IntentState = "IDLE"
		Runtime.IntentConfidence = 0
		Runtime.IntentAimX = nil
		Runtime.IntentAimY = nil
		Runtime.IntentEvidence = "NONE"
		Runtime.IntentStableSince = 0
		Runtime.IntentUntil = 0
		Runtime.IntentReleasePlayer = nil
		Runtime.IntentReleaseUntil = 0
		Runtime.PossessorStablePlayer = nil
		Runtime.PossessorStableSince = 0
		Runtime.VirtualGateGoal = nil
		Runtime.VirtualGateLastDepth = nil
		Runtime.VirtualGateLastTime = nil
		Runtime.VirtualGateLastCrossDepth = nil
		Runtime.VirtualGateLastCrossTime = nil
		Runtime.VirtualGateCrossCount = 0
		Runtime.VirtualGateSpeed = 0
		Runtime.VirtualGateConfidence = 0
		Tracker.History = {}
		Tracker.Measurements = {}
		Tracker.LastAcceptedVelocity = Vector3.zero
		Tracker.PhysicsBall = nil
		Tracker.Dataset = nil
		Tracker.DatasetModel = nil
		Tracker.CurveVelocity = Vector3.zero
		Tracker.UpForceVelocity = Vector3.zero
		Tracker.Position = nil
		Tracker.MeasurementPosition = nil
		Tracker.FilterPosition = nil
		Tracker.FilterVelocity = Vector3.zero
		Tracker.FilterAcceleration = Vector3.zero
		Tracker.LastFilterTime = 0
		Tracker.CurveAcceleration = Vector3.zero
		Tracker.CurveDirection = Vector3.zero
		Tracker.CurveFrames = 0
		Tracker.CurveConfirmed = false
		Tracker.LastTime = 0
		Tracker.LastPredictionState = nil
		Tracker.RawVelocity = best and best.AssemblyLinearVelocity or Vector3.zero
		Tracker.Velocity = Tracker.RawVelocity
		Tracker.Acceleration = Vector3.zero
		Tracker.Grounded, Tracker.GroundY = false, nil
		Runtime.Event = best and ("BALL LOCK " .. best.Name) or "BALL LOST"
	end
	return Tracker.Ball
end

local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.IgnoreWater = true

local function detectGround(ball)
	local ballRoot, ancestor = ball, ball.Parent
	for _ = 1, 4 do
		if not ancestor or ancestor == Workspace then break end
		if ballNameBonus(ancestor.Name) > 0 then ballRoot = ancestor end
		ancestor = ancestor.Parent
	end
	local ignore = {ballRoot}
	if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
	groundParams.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(ball.Position, Vector3.new(0, -CONFIG.GroundRayDistance, 0), groundParams)
	if not hit then return false, nil end
	local ballBottom = ball.Position.Y - ball.Size.Y * 0.5
	local grounded = ballBottom - hit.Position.Y <= CONFIG.GroundTolerance and math.abs(ball.AssemblyLinearVelocity.Y) <= CONFIG.GroundVerticalLimit
	return grounded, hit.Position.Y + ball.Size.Y * 0.5
end

local function resetTrajectory(reason, now, originPosition)
	now = now or os.clock()
	Runtime.TrajectoryId += 1
	Runtime.TrajectoryReason = reason
	Runtime.DivedTrajectoryId = -1
	Runtime.ShotConfidence = 0
	Runtime.ShotUrgency = "DETECTED"
	Runtime.PredictedGoalImpact = nil
	Runtime.PredictionCorridorMinX = nil
	Runtime.PredictionCorridorMaxX = nil
	Runtime.PredictionCorridorMinY = nil
	Runtime.PredictionCorridorMaxY = nil
	Runtime.ShotOriginPosition = originPosition or Tracker.Position
	Runtime.ShotDistanceClass = "UNKNOWN"
	Runtime.StableInterceptX = nil
	Runtime.StableInterceptY = nil
	Runtime.StableInterceptTime = nil
	Runtime.StableInterceptShotId = Runtime.TrajectoryId
	Runtime.DiveCandidateShotId = Runtime.TrajectoryId
	Runtime.DiveCandidateSide = 0
	Runtime.DiveCandidateFrames = 0
	Runtime.VirtualGateShotId = Runtime.TrajectoryId
	Runtime.VirtualGateGoal = nil
	Runtime.VirtualGateLastDepth = nil
	Runtime.VirtualGateLastTime = nil
	Runtime.VirtualGateLastCrossDepth = nil
	Runtime.VirtualGateLastCrossTime = nil
	Runtime.VirtualGateCrossCount = 0
	Runtime.VirtualGateSpeed = 0
	Runtime.VirtualGateConfidence = 0
	Runtime.VirtualGateLastEvent = -100
	Runtime.PredictionConfidence = 0
	Runtime.PredictionUncertainty = 1
	Runtime.PredictionModelSince = now
	Runtime.PredictionLastModel = "CV"
	Runtime.RunETA = math.huge
	Runtime.DiveETA = math.huge
	Runtime.BallETA = math.huge
	Runtime.SaveMethod = "DETECTED"
	Tracker.Model = "CV"
	Tracker.LastPredictionState = nil
	Tracker.History = {}
	Tracker.Measurements = {}
	Tracker.ModelErrors = {CV = 1, GRAVITY = 1, ACCEL = 1, CURVE = 1, GROUND = 1}
	Tracker.CurveFrames = 0
	Tracker.CurveConfirmed = false
	Runtime.Event = reason
end

local function resetShot(reason, now, originPosition)
	now = now or os.clock()
	Runtime.ShotId += 1
	Runtime.LastKick = now
	Runtime.IntentState = reason == "NEW SHOT" and "BALL RELEASE" or reason
	Runtime.IntentReleaseUntil = now + CONFIG.PreShotReleaseMemory
	resetTrajectory(reason, now, originPosition)
end

local function advanceCurveState(state, step, measuredCurve, measured, initialHorizontalSpeed, groundY)
	local predictedPosition = state.position
	local predictedVelocity = state.velocity
	local currentCurve = state.curve
	local horizontalVelocity = horizontal(predictedVelocity)
	local horizontalSpeed = horizontalVelocity.Magnitude
	local direction = safeUnit(horizontalVelocity)
	local speedRatio = initialHorizontalSpeed / math.max(horizontalSpeed, 1)
	local curveScale = math.clamp(speedRatio, 1, CONFIG.CurveSlowSpeedBoostMaximum)
	local desiredCurve = measuredCurve * curveScale
	local curveDelta = desiredCurve - currentCurve
	local maximumCurveChange = CONFIG.CurveAccelerationChangeRate * step
	if curveDelta.Magnitude > maximumCurveChange then
		curveDelta = curveDelta.Unit * maximumCurveChange
	end
	currentCurve += curveDelta

	local longitudinalAcceleration = 0
	if direction.Magnitude > 0.01 then
		longitudinalAcceleration = math.min(0, horizontal(measured):Dot(direction))
	end

	local nearGround = groundY ~= nil
		and predictedPosition.Y <= groundY + CONFIG.CurveGroundHeightTolerance
		and predictedVelocity.Y <= 0
	local acceleration
	if nearGround then
		local groundDeceleration = math.max(Tracker.GroundDeceleration, -longitudinalAcceleration)
		acceleration = currentCurve - direction * groundDeceleration
		predictedPosition = Vector3.new(predictedPosition.X, groundY, predictedPosition.Z)
		predictedVelocity = Vector3.new(predictedVelocity.X, 0, predictedVelocity.Z)
	else
		local verticalLift = math.clamp(
			measured.Y + Workspace.Gravity,
			-Workspace.Gravity * 0.35,
			Workspace.Gravity * 0.65
		)
		acceleration = currentCurve
			+ direction * longitudinalAcceleration
			+ Vector3.new(0, -Workspace.Gravity + verticalLift, 0)
	end

	local nextVelocity = predictedVelocity + acceleration * step
	if direction.Magnitude > 0.01 and horizontal(nextVelocity):Dot(direction) < 0 then
		nextVelocity = Vector3.new(0, nextVelocity.Y, 0)
	end
	predictedPosition += (predictedVelocity + nextVelocity) * (0.5 * step)
	return {position = predictedPosition, velocity = nextVelocity, curve = currentCurve}
end

local function predictCurvePosition(position, velocity, curveAcceleration, measuredAcceleration, time, groundY)
	local measuredCurve = horizontal(curveAcceleration or Vector3.zero)
	local measured = measuredAcceleration or Vector3.zero
	local initialHorizontalSpeed = horizontal(velocity).Magnitude
	local state = {position = position, velocity = velocity, curve = measuredCurve}
	local remaining = math.max(0, time)
	while remaining > 0 do
		local step = math.min(CONFIG.CurvePredictionStep, remaining)
		state = advanceCurveState(state, step, measuredCurve, measured, initialHorizontalSpeed, groundY)
		remaining -= step
	end
	return state.position
end

local function predictTrackedCurvePosition(time)
	time = math.max(0, time)
	if Tracker.CurvePredictionCacheStamp ~= Tracker.LastTime or not Tracker.CurvePredictionCache then
		local measuredCurve = horizontal(Tracker.CurveAcceleration or Vector3.zero)
		Tracker.CurvePredictionCacheStamp = Tracker.LastTime
		Tracker.CurvePredictionCache = {
			measuredCurve = measuredCurve,
			measured = Tracker.Acceleration or Vector3.zero,
			initialHorizontalSpeed = horizontal(Tracker.Velocity).Magnitude,
			groundY = Tracker.GroundY,
			states = {{position = Tracker.Position, velocity = Tracker.Velocity, curve = measuredCurve}},
		}
	end
	local cache = Tracker.CurvePredictionCache
	local step = CONFIG.CurvePredictionStep
	local upperIndex = math.ceil(time / step)
	while #cache.states <= upperIndex do
		local previous = cache.states[#cache.states]
		table.insert(cache.states, advanceCurveState(
			previous,
			step,
			cache.measuredCurve,
			cache.measured,
			cache.initialHorizontalSpeed,
			cache.groundY
		))
	end
	local lowerIndex = math.floor(time / step)
	local lowerState = cache.states[lowerIndex + 1]
	local upperState = cache.states[math.min(upperIndex + 1, #cache.states)]
	if lowerIndex == upperIndex then return lowerState.position end
	return lowerState.position:Lerp(upperState.position, (time - lowerIndex * step) / step)
end

local function updateModelErrors(position, now)
	local previous = Tracker.LastPredictionState
	if not previous then return end
	local dt = now - previous.time
	if dt <= 0 or dt > 0.15 then return end
	local predictions = {
		CV = previous.position + previous.velocity * dt,
		GRAVITY = previous.position + previous.velocity * dt + Vector3.new(0, -0.5 * Workspace.Gravity * dt * dt, 0),
		ACCEL = previous.position + previous.velocity * dt + 0.5 * previous.acceleration * dt * dt,
		CURVE = predictCurvePosition(
			previous.position,
			previous.velocity,
			previous.curveAcceleration,
			previous.acceleration,
			dt,
			previous.groundY
		),
	}
	for model, predicted in pairs(predictions) do
		local errorValue = (position - predicted).Magnitude
		Tracker.ModelErrors[model] = lerp(Tracker.ModelErrors[model], errorValue, CONFIG.ModelErrorAlpha)
	end
end

local function choosePredictionModel()
	if Tracker.Grounded then
		Tracker.Model = Tracker.CurveConfirmed and "CURVE" or "GROUND"
		return
	end
	local bestModel, bestError = Tracker.Model, Tracker.ModelErrors[Tracker.Model] or math.huge
	local candidates = Tracker.CurveConfirmed and {"CV", "GRAVITY", "ACCEL", "CURVE"} or {"CV", "GRAVITY", "ACCEL"}
	for _, model in ipairs(candidates) do
		local modelError = Tracker.ModelErrors[model]
		if modelError + CONFIG.ModelSwitchMargin < bestError then bestModel, bestError = model, modelError end
	end
	Tracker.Model = bestModel
end

local function findPhysicsBall(ball)
	if not ball then return nil end
	if ball.Name == "ServerBall" then return ball end
	local current = ball
	for _ = 1, 5 do
		if not current or current == Workspace then break end
		local serverBall = current:FindFirstChild("ServerBall", true)
		if serverBall and serverBall:IsA("BasePart") then return serverBall end
		current = current.Parent
	end
	return nil
end

local function getGameBallModel(object)
	local current = object
	for _ = 1, 6 do
		if not current or current == Workspace then break end
		if current:IsA("Model") and (current.Name == "GameBall" or current:FindFirstChild("ClientBall") or current:FindFirstChild("ServerBall")) then
			return current
		end
		current = current.Parent
	end
	return nil
end

local function getNativeBallDataset(object)
	if not CONFIG.PreferNativeBallDataset or typeof(Runtime.ClientBall) ~= "table" then return nil, nil end
	local datasets = Runtime.ClientBall.BallDatasets
	if typeof(datasets) ~= "table" then return nil, nil end
	local model = getGameBallModel(object)
	if model and typeof(datasets[model]) == "table" then return datasets[model], model end
	for candidate, dataset in pairs(datasets) do
		if typeof(candidate) == "Instance" and typeof(dataset) == "table" then
			if object == candidate or object:IsDescendantOf(candidate) then return dataset, candidate end
		end
	end
	return nil, model
end

local function getNetworkPing()
	local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
	if ok and typeof(ping) == "number" and ping == ping then return math.clamp(ping, 0, 0.5) end
	return 0
end

local function getDatasetAge(dataset, now)
	if not dataset then return 0 end
	local stamp = dataset.LastServerBallUpdate
	if typeof(stamp) ~= "number" or stamp ~= stamp then return 0 end
	local candidates = {now - stamp}
	local ok, serverNow = pcall(function() return Workspace:GetServerTimeNow() end)
	if ok and typeof(serverNow) == "number" then table.insert(candidates, serverNow - stamp) end
	local best = math.huge
	for _, age in ipairs(candidates) do
		if age >= 0 and age <= CONFIG.DatasetMaximumAge then best = math.min(best, age) end
	end
	return best < math.huge and best or 0
end

local function updateCurveEstimate(acceleration, velocity)
	local direction = safeUnit(horizontal(velocity))
	if direction.Magnitude < 0.01 then
		Tracker.CurveFrames = 0
		Tracker.CurveConfirmed = false
		Tracker.CurveAcceleration = Vector3.zero
		return
	end
	local horizontalAcceleration = horizontal(acceleration)
	local lateral = horizontalAcceleration - direction * horizontalAcceleration:Dot(direction)
	local magnitude = lateral.Magnitude
	if magnitude < CONFIG.CurveMinimumAcceleration then
		Tracker.CurveFrames = math.max(0, Tracker.CurveFrames - 1)
		if Tracker.CurveFrames == 0 then Tracker.CurveConfirmed = false end
		Tracker.CurveAcceleration = Tracker.CurveAcceleration:Lerp(Vector3.zero, 0.25)
		return
	end
	if magnitude > CONFIG.CurveMaximumAcceleration then lateral = lateral.Unit * CONFIG.CurveMaximumAcceleration end
	local lateralDirection = safeUnit(lateral)
	local consistent = Tracker.CurveDirection.Magnitude < 0.01
		or Tracker.CurveDirection:Dot(lateralDirection) >= CONFIG.CurveConsistencyDot
	if consistent then
		Tracker.CurveFrames += 1
	else
		Tracker.CurveFrames = 1
		Tracker.CurveAcceleration = Vector3.zero
	end
	Tracker.CurveDirection = lateralDirection
	Tracker.CurveAcceleration = Tracker.CurveAcceleration:Lerp(lateral, 0.34)
	Tracker.CurveConfirmed = Tracker.CurveFrames >= CONFIG.CurveConfirmationFrames
end

local function filterBallState(measurementPosition, measuredVelocity, now, resetFilter)
	local dt = Tracker.LastFilterTime > 0 and math.clamp(now - Tracker.LastFilterTime, 0.001, CONFIG.FilterMaximumStep) or 0
	if resetFilter or not Tracker.FilterPosition or dt <= 0
		or (measurementPosition - Tracker.FilterPosition).Magnitude >= CONFIG.FilterResetDistance then
		Tracker.FilterPosition = measurementPosition
		Tracker.FilterVelocity = measuredVelocity
		Tracker.FilterAcceleration = Vector3.zero
		Tracker.LastFilterTime = now
		updateCurveEstimate(Vector3.zero, measuredVelocity)
		return measurementPosition, measuredVelocity, Vector3.zero
	end
	local predicted = Tracker.FilterPosition + Tracker.FilterVelocity * dt + 0.5 * Tracker.FilterAcceleration * dt * dt
	local residual = measurementPosition - predicted
	local speedRatio = clamp01(measuredVelocity.Magnitude / math.max(CONFIG.FastShotImmediateSpeed, 1))
	local alpha = lerp(CONFIG.FilterAlphaSlow, CONFIG.FilterAlphaFast, speedRatio)
	local beta = lerp(CONFIG.FilterBetaSlow, CONFIG.FilterBetaFast, speedRatio)
	local oldVelocity = Tracker.FilterVelocity
	Tracker.FilterPosition = predicted + residual * alpha
	Tracker.FilterVelocity = Tracker.FilterVelocity + residual * (beta / dt)
	Tracker.FilterVelocity = Tracker.FilterVelocity:Lerp(measuredVelocity, 0.18 + speedRatio * 0.24)
	local accelerationMeasurement = (Tracker.FilterVelocity - oldVelocity) / dt
	if accelerationMeasurement.Magnitude > CONFIG.AccelerationClamp then
		accelerationMeasurement = accelerationMeasurement.Unit * CONFIG.AccelerationClamp
	end
	Tracker.FilterAcceleration = Tracker.FilterAcceleration:Lerp(accelerationMeasurement, CONFIG.FilterGamma)
	Tracker.LastFilterTime = now
	updateCurveEstimate(Tracker.FilterAcceleration, Tracker.FilterVelocity)
	return Tracker.FilterPosition, Tracker.FilterVelocity, Tracker.FilterAcceleration
end

local function readLinearVelocity(part, name)
	local object = part and part:FindFirstChild(name, true)
	if not object or not object:IsA("LinearVelocity") then return Vector3.zero end
	local velocity = object.VectorVelocity
	if velocity.Magnitude > CONFIG.ForceVelocityClamp then velocity = velocity.Unit * CONFIG.ForceVelocityClamp end
	return velocity
end

local function recordBallMeasurement(now, position)
	table.insert(Tracker.Measurements, {time = now, position = position})
	while #Tracker.Measurements > CONFIG.MeasurementWindow
		or (#Tracker.Measurements > 2 and now - Tracker.Measurements[1].time > CONFIG.MeasurementMaximumAge) do
		table.remove(Tracker.Measurements, 1)
	end
end

local function regressionBallVelocity()
	local count = #Tracker.Measurements
	if count < 3 then return nil end
	local originTime = Tracker.Measurements[count].time
	local meanTime, meanPosition = 0, Vector3.zero
	for _, sample in ipairs(Tracker.Measurements) do
		meanTime += sample.time - originTime
		meanPosition += sample.position
	end
	meanTime /= count
	meanPosition /= count
	local numerator = Vector3.zero
	local denominator = 0
	for _, sample in ipairs(Tracker.Measurements) do
		local centeredTime = (sample.time - originTime) - meanTime
		numerator += (sample.position - meanPosition) * centeredTime
		denominator += centeredTime * centeredTime
	end
	if denominator <= 0.000001 then return nil end
	local velocity = numerator / denominator
	if velocity.Magnitude > CONFIG.MaxBallSpeed then velocity = velocity.Unit * CONFIG.MaxBallSpeed end
	return velocity
end

local function sampleBall(now)
	local ball = discoverBall(false)
	if not ball then return nil end
	local sourceChanged = Runtime.BallSourceChanged
	Runtime.BallSourceChanged = false
	local physicsBall = findPhysicsBall(ball)
	if physicsBall and (physicsBall.Position - ball.Position).Magnitude > CONFIG.PhysicalBallMaximumSeparation then
		physicsBall = nil
	end
	local samplePart = physicsBall or ball
	Tracker.PhysicsBall = physicsBall
	local dataset, datasetModel = getNativeBallDataset(ball)
	Tracker.Dataset, Tracker.DatasetModel = dataset, datasetModel
	Tracker.CurveVelocity = readLinearVelocity(samplePart, "Curve")
	Tracker.UpForceVelocity = readLinearVelocity(samplePart, "UpForce")
	local replicatedCFrame = dataset and dataset.ServerBallCFrame
	local replicatedVelocity = dataset and dataset.ServerBallVelocity
	local hasDatasetPosition = typeof(replicatedCFrame) == "CFrame"
	local hasDatasetVelocity = typeof(replicatedVelocity) == "Vector3"
	local measurementPosition = hasDatasetPosition and replicatedCFrame.Position or samplePart.Position
	local dataAge = hasDatasetPosition and getDatasetAge(dataset, now) or 0
	local ping = getNetworkPing()
	local extrapolation = math.clamp(dataAge + ping * CONFIG.NetworkPingWeight, 0, CONFIG.MaximumLatencyExtrapolation)
	local position = measurementPosition
	local raw = hasDatasetVelocity and replicatedVelocity or samplePart.AssemblyLinearVelocity
	position += raw * extrapolation + 0.5 * Tracker.FilterAcceleration * extrapolation * extrapolation
	Tracker.MeasurementPosition = measurementPosition
	Tracker.MeasurementAge = dataAge
	Tracker.NetworkPing = ping
	if raw.Magnitude > CONFIG.MaxBallSpeed then raw = raw.Unit * CONFIG.MaxBallSpeed end
	updateModelErrors(position, now)
	local dt = Tracker.LastTime > 0 and now - Tracker.LastTime or 0
	local observed = raw
	if Tracker.Position and dt > 0.004 then observed = (position - Tracker.Position) / dt end
	if observed.Magnitude > CONFIG.MaxBallSpeed then observed = observed.Unit * CONFIG.MaxBallSpeed end
	local oldVelocity = Tracker.Velocity
	local jump = (raw - Tracker.RawVelocity).Magnitude
	local directionAngle = angleBetween(horizontal(Tracker.RawVelocity), horizontal(raw))
	local grounded, groundY = detectGround(samplePart)
	local bounce = oldVelocity.Y < -5 and raw.Y > 4 and groundY and math.abs(position.Y - groundY) < 2.2
	local impossiblePositionJump = Tracker.Position and dt > 0 and dt <= CONFIG.FilterMaximumStep * 1.5
		and (position - Tracker.Position).Magnitude > CONFIG.BallContinuityDistance
	local newShot = sourceChanged
	if sourceChanged then
		resetTrajectory("BALL SOURCE CHANGED", now, position)
	elseif impossiblePositionJump then
		resetShot("BALL TELEPORT / RESET", now, position)
		newShot = true
	elseif bounce then
		Tracker.LastBounce = now
		resetShot("BOUNCE", now, position)
		newShot = true
	elseif directionAngle >= CONFIG.RicochetAngle and raw.Magnitude >= CONFIG.KickMinimumSpeed then
		resetShot("RICOCHET", now, position)
		newShot = true
	elseif jump >= CONFIG.KickSpeedJump and raw.Magnitude >= CONFIG.KickMinimumSpeed and now - Runtime.LastKick > 0.10 then
		resetShot("NEW SHOT", now, position)
		newShot = true
	end
	local postDiveTracking = Runtime.Diving
		or Runtime.SavePhase == "CONTACT_WINDOW"
		or Runtime.SavePhase == "GETTING_UP"
		or now <= Runtime.ReboundUntil
	local keeper = postDiveTracking and getKeeperPosition() or nil
	local previousDiveVelocity = Runtime.DivePreviousBallVelocity or Tracker.LastAcceptedVelocity
	local velocityChange = (raw - previousDiveVelocity).Magnitude
	local deflectionAngle = angleBetween(raw, previousDiveVelocity)
	local nearDiveContact = keeper and (position - keeper).Magnitude <= CONFIG.DeflectionContactDistance
	local goal = Runtime.DefendedGoal
	local wasGoalward = goal and previousDiveVelocity:Dot(goal.field) < -CONFIG.MinimumGoalwardSpeed
	local nowGoalward = goal and raw:Dot(goal.field) < -CONFIG.MinimumGoalwardSpeed
	local weakBlock = previousDiveVelocity.Magnitude >= 3
		and raw.Magnitude <= previousDiveVelocity.Magnitude * 0.68
		and velocityChange >= CONFIG.WeakDeflectionSpeedChange
	local reversedAwayFromGoal = wasGoalward and not nowGoalward
	if nearDiveContact and now - Runtime.LastDeflectionAt >= CONFIG.DeflectionMemoryTime
		and previousDiveVelocity.Magnitude >= 0.5
		and (velocityChange >= CONFIG.DeflectionSpeedChange
			or deflectionAngle >= CONFIG.DeflectionMinimumAngle
			or weakBlock or reversedAwayFromGoal) then
		Runtime.LastDeflectionAt = now
		Runtime.DiveContactDetected = true
		Runtime.DiveContactKind = "DEFLECTION"
		Runtime.DiveContactPosition = position
		learnDiveContact(now, "DEFLECTION")
		Runtime.RecoveryRequired = true
		Runtime.RecoveryReason = "POST-DIVE DEFLECTION"
		Runtime.ReboundUntil = now + CONFIG.ReboundDefenseTime
		resetTrajectory("KEEPER DEFLECTION", now, position)
		newShot = true
	end
	if postDiveTracking then Runtime.DivePreviousBallVelocity = raw end
	if newShot then Tracker.Measurements = {} end
	recordBallMeasurement(now, position)
	local regressionVelocity = regressionBallVelocity()
	if regressionVelocity and not newShot then
		raw = raw:Lerp(regressionVelocity, CONFIG.RegressionVelocityBlend)
	end
	local rawWeight = now - Runtime.LastKick <= CONFIG.RawVelocityWindow and 0.90 or 0.68
	local velocity = raw:Lerp(observed, 1 - rawWeight)
	local immediateVelocity = newShot
		or now - Runtime.LastKick <= CONFIG.ImmediateVelocityWindow
		or raw.Magnitude >= CONFIG.AlwaysRawAboveSpeed
	-- Bei einem neuen/gewaltigen Schuss darf die alte langsame Ballbewegung
	-- nicht noch mehrere Frames in die Prognose gemischt werden.
	Tracker.Velocity = (oldVelocity.Magnitude < 0.01 or immediateVelocity) and velocity or oldVelocity:Lerp(velocity, 0.52)
	if newShot then Tracker.Acceleration = Vector3.zero end
	if dt > 0.004 and not newShot then
		local acceleration = (Tracker.Velocity - oldVelocity) / dt
		if acceleration.Magnitude > CONFIG.AccelerationClamp then acceleration = acceleration.Unit * CONFIG.AccelerationClamp end
		Tracker.Acceleration = Tracker.Acceleration:Lerp(acceleration, 0.24)
		local oldSpeed, newSpeed = horizontal(oldVelocity).Magnitude, horizontal(Tracker.Velocity).Magnitude
		if grounded and oldSpeed > newSpeed and oldSpeed > 2 then
			local deceleration = math.clamp((oldSpeed - newSpeed) / dt, 0, CONFIG.MaximumGroundDeceleration)
			Tracker.GroundDeceleration = lerp(Tracker.GroundDeceleration, deceleration, 0.10)
		end
	end
	local filteredPosition, filteredVelocity, filteredAcceleration = filterBallState(position, Tracker.Velocity, now, newShot)
	position = filteredPosition
	Tracker.Velocity = filteredVelocity
	Tracker.Acceleration = filteredAcceleration
	Tracker.RawVelocity = raw
	Tracker.LastAcceptedVelocity = raw
	Tracker.Grounded, Tracker.GroundY = grounded, groundY
	Tracker.Position, Tracker.LastTime = position, now
	Tracker.LastPredictionState = {
		time = now,
		position = position,
		velocity = Tracker.Velocity,
		acceleration = Tracker.Acceleration,
		curveAcceleration = Tracker.CurveAcceleration,
		groundY = Tracker.GroundY,
	}
	table.insert(Tracker.History, {time = now, position = position, velocity = Tracker.Velocity})
	while #Tracker.History > CONFIG.MaxHistory or (#Tracker.History > 2 and now - Tracker.History[1].time > CONFIG.HistoryWindow) do table.remove(Tracker.History, 1) end
	choosePredictionModel()
	return ball
end

local function predictBallAt(time)
	local p, v = Tracker.Position, Tracker.Velocity
	if not p then return nil end
	if Tracker.Model == "GROUND" then
		local horizontalVelocity = horizontal(v)
		local speed = horizontalVelocity.Magnitude
		local distance = math.max(0, speed * time - 0.5 * Tracker.GroundDeceleration * time * time)
		return Vector3.new(p.X, Tracker.GroundY or p.Y, p.Z) + safeUnit(horizontalVelocity) * distance
	elseif Tracker.Model == "GRAVITY" then
		return p + v * time + Vector3.new(0, -0.5 * Workspace.Gravity * time * time, 0)
	elseif Tracker.Model == "ACCEL" then
		return p + v * time + 0.5 * Tracker.Acceleration * time * time
	elseif Tracker.Model == "CURVE" then
		return predictTrackedCurvePosition(time)
	end
	return p + v * time
end

local function updatePredictionConfidence(now)
	if Runtime.PredictionLastModel ~= Tracker.Model then
		Runtime.PredictionLastModel = Tracker.Model
		Runtime.PredictionModelSince = now
	end
	if Runtime.PredictionModelSince <= 0 then Runtime.PredictionModelSince = now end
	local historyConfidence = clamp01((#Tracker.History - 1) / math.max(CONFIG.PredictionMinimumHistory - 1, 1))
	local chosenError = Tracker.ModelErrors[Tracker.Model] or math.huge
	local errorConfidence = 1 - clamp01(chosenError / CONFIG.PredictionErrorScale)
	local speedReference = math.max(Tracker.RawVelocity.Magnitude, Tracker.Velocity.Magnitude, 10)
	local velocityNoise = (Tracker.RawVelocity - Tracker.Velocity).Magnitude / speedReference
	local velocityConfidence = 1 - clamp01(velocityNoise / CONFIG.PredictionVelocityNoiseScale)
	local stableConfidence = clamp01((now - Runtime.PredictionModelSince) / CONFIG.PredictionStableTime)
	local ageConfidence = 1 - clamp01(Tracker.MeasurementAge / math.max(CONFIG.DatasetMaximumAge, 0.01))
	local confidence = historyConfidence * 0.22 + errorConfidence * 0.27
		+ velocityConfidence * 0.22 + stableConfidence * 0.14 + ageConfidence * 0.15
	-- Eine erkannte Kurve darf erst dann volle Sicherheit erhalten, wenn auch
	-- das Curve-Modell die kleinste gemessene Abweichung besitzt.
	if Tracker.CurveConfirmed and Tracker.Model ~= "CURVE" then confidence *= 0.90 end
	-- Unmittelbar nach Bounce/Ricochet ist die alte Bahn absichtlich wertlos.
	-- Die Sicherheit steigt danach automatisch mit den neuen Messpunkten.
	if now - Tracker.LastBounce < CONFIG.PredictionStableTime then confidence = math.min(confidence, 0.34) end
	if now - Runtime.LastKick < 0.045 then confidence = math.min(confidence, 0.46) end
	Runtime.PredictionConfidence = clamp01(confidence)
	Runtime.PredictionUncertainty = 1 - Runtime.PredictionConfidence
	return Runtime.PredictionConfidence
end

local function findPlaneIntercept(goal, targetDepth)
	if not Tracker.Position then return nil end
	local currentLocal = goalToLocal(goal, Tracker.Position)
	local localVelocity = Vector3.new(Tracker.Velocity:Dot(goal.right), Tracker.Velocity.Y, Tracker.Velocity:Dot(goal.field))
	if localVelocity.Z >= -CONFIG.MinimumGoalwardSpeed or currentLocal.Z <= targetDepth then return nil end
	local previousTime = 0
	local previousDepth = currentLocal.Z
	for t = CONFIG.PredictionStep, CONFIG.MaximumPredictionTime, CONFIG.PredictionStep do
		local predicted = predictBallAt(t)
		local depth = goalToLocal(goal, predicted).Z
		if previousDepth > targetDepth and depth <= targetDepth then
			local lowTime, highTime = previousTime, t
			for _ = 1, CONFIG.InterceptRefinementIterations do
				local middle = (lowTime + highTime) * 0.5
				local middlePosition = predictBallAt(middle)
				local middleDepth = goalToLocal(goal, middlePosition).Z
				if middleDepth > targetDepth then lowTime = middle else highTime = middle end
				if highTime - lowTime <= CONFIG.InterceptTimeTolerance then break end
			end
			local hitTime = (lowTime + highTime) * 0.5
			local hitPosition = predictBallAt(hitTime) + Runtime.PredictionBias
			local velocityStep = math.min(0.008, math.max(hitTime * 0.25, 0.002))
			local before = predictBallAt(math.max(0, hitTime - velocityStep))
			local after = predictBallAt(math.min(CONFIG.MaximumPredictionTime, hitTime + velocityStep))
			local incomingVelocity = (after - before) / math.max(math.min(CONFIG.MaximumPredictionTime, hitTime + velocityStep) - math.max(0, hitTime - velocityStep), 0.001)
			local uncertainty = CONFIG.PredictionBaseUncertainty
				+ Tracker.MeasurementAge * CONFIG.PredictionAgeUncertaintyScale
				+ hitTime * CONFIG.PredictionTimeUncertaintyScale * Runtime.PredictionUncertainty
			local localHit = goalToLocal(goal, hitPosition)
			local lateralUncertainty = uncertainty * CONFIG.PredictionCorridorLateralScale
			local verticalUncertainty = uncertainty * CONFIG.PredictionCorridorVerticalScale
			return {
				time = hitTime,
				position = hitPosition,
				localPosition = localHit,
				incomingVelocity = incomingVelocity,
				uncertainty = uncertainty,
				corridorMinX = localHit.X - lateralUncertainty,
				corridorMaxX = localHit.X + lateralUncertainty,
				corridorMinY = hitPosition.Y - verticalUncertainty,
				corridorMaxY = hitPosition.Y + verticalUncertainty,
			}
		end
		previousTime, previousDepth = t, depth
	end
	return nil
end

local function isOnTarget(goal, intercept)
	if not intercept then return false end
	local minX = intercept.corridorMinX or intercept.localPosition.X
	local maxX = intercept.corridorMaxX or intercept.localPosition.X
	local minY = intercept.corridorMinY or intercept.position.Y
	local maxY = intercept.corridorMaxY or intercept.position.Y
	return maxX >= -goal.halfWidth - CONFIG.GoalWidthMargin
		and minX <= goal.halfWidth + CONFIG.GoalWidthMargin
		and maxY >= goal.bottomY - CONFIG.GoalHeightMargin
		and minY <= goal.topY + CONFIG.GoalHeightMargin
end

--==============================================================
-- WELTBEWEGUNG -> KAMERAABHÄNGIGER CONTROLMODULE-INPUT
--==============================================================

local function worldToMoveVector(worldDirection, strength)
	local desired = safeUnit(horizontal(worldDirection))
	if desired.Magnitude < 0.01 then return Vector3.zero end
	local camera = Workspace.CurrentCamera
	if not camera then return Vector3.new(desired.X, 0, desired.Z) * strength * Runtime.InputPolarity end
	local right = safeUnit(horizontal(camera.CFrame.RightVector))
	local forward = safeUnit(horizontal(camera.CFrame.LookVector))
	if right.Magnitude < 0.01 or forward.Magnitude < 0.01 then
		return Vector3.new(desired.X, 0, desired.Z) * strength * Runtime.InputPolarity
	end
	local localX = desired:Dot(right)
	local localZ = -desired:Dot(forward)
	local result = Vector3.new(localX, 0, localZ)
	return result.Magnitude > 0.01 and result.Unit * strength * Runtime.InputPolarity or Vector3.zero
end

local function setWorldTarget(goal, target, reason, allowOutsidePosts)
	if not goal or not target then
		Runtime.WorldTarget = nil
		return
	end
	local now = os.clock()
	if Runtime.InputCalibrationState == "FAILED" then
		Runtime.ForcedMoveVector = Vector3.zero
		Runtime.ForcedMoveOwner = "BOT"
		return
	end
	if now < Runtime.MovementFaultUntil then
		Runtime.ForcedMoveVector = Vector3.zero
		Runtime.ForcedMoveOwner = "BOT"
		return
	end
	if now < Runtime.BoundaryRetreatUntil and Runtime.BoundaryRetreatTarget then
		Runtime.WorldTarget = Runtime.BoundaryRetreatTarget
		Runtime.AllowOutsidePosts = false
		Runtime.TargetReason = "BOUNDARY RETREAT"
		Runtime.TargetArrived = false
		return
	end
	if now >= Runtime.BoundaryRetreatUntil then Runtime.BoundaryRetreatTarget = nil end
	local safeTarget = clampSafeTarget(goal, target, allowOutsidePosts)
	if Runtime.WorldTarget
		and horizontal(safeTarget - Runtime.WorldTarget).Magnitude > CONFIG.TargetJumpMaximumDistance then
		Runtime.MovementFaultUntil = now + 0.75
		Runtime.WorldTarget = nil
		Runtime.TargetReason = "TARGET FAULT"
		Runtime.TargetArrived = false
		Runtime.ForcedMoveVector = Vector3.zero
		Runtime.ForcedMoveOwner = "BOT"
		Runtime.Event = "TARGET JUMP REJECTED"
		return
	end
	if Runtime.WorldTarget and horizontal(safeTarget - Runtime.WorldTarget).Magnitude >= CONFIG.ArrivalExitDistance then
		Runtime.TargetArrived = false
		Runtime.WrongDirectionSamples = 0
		Runtime.CorrectDirectionSamples = 0
	end
	Runtime.WorldTarget = safeTarget
	Runtime.AllowOutsidePosts = allowOutsidePosts == true
	Runtime.TargetReason = reason or "MOVE"
end

local function clearWorldTarget()
	Runtime.WorldTarget = nil
	Runtime.AllowOutsidePosts = false
	Runtime.TargetArrived = false
	Runtime.BoundaryStuckCount = 0
	Runtime.BoundaryRetreatUntil = 0
	Runtime.BoundaryRetreatTarget = nil
	Runtime.WrongDirectionSamples = 0
	Runtime.CorrectDirectionSamples = 0
	Runtime.TargetReason = "NONE"
	if Runtime.ForcedMoveOwner == "BOT" then Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil end
end

RunService:BindToRenderStep("SpecialGKBotV23Movement", Enum.RenderPriority.Input.Value - 1, function()
	if Runtime.ForcedMoveOwner == "DIVE" then return end
	local saveMovementLocked = Runtime.SavePhase == "DIVE_ACTIVE"
		or Runtime.SavePhase == "CONTACT_WINDOW"
		or Runtime.SavePhase == "GETTING_UP"
	if not Options.Bot or not Runtime.CalibrationOK or Runtime.HoldingBall or Runtime.Diving
		or saveMovementLocked or os.clock() < Runtime.MovementFaultUntil or not Runtime.WorldTarget then
		if Runtime.ForcedMoveOwner == "BOT" then Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil end
		return
	end
	local keeper = getKeeperPosition()
	local goal = Runtime.DefendedGoal
	if not keeper or not goal then
		Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = Vector3.zero, "BOT"
		return
	end
	local safeTarget = clampSafeTarget(goal, Runtime.WorldTarget, Runtime.AllowOutsidePosts)
	Runtime.WorldTarget = safeTarget
	local difference = horizontal(safeTarget - keeper)
	local keeperLocal = goalToLocal(goal, keeper)
	local minX, maxX, minDepth, maxDepth = getGoalMovementBounds(goal, Runtime.AllowOutsidePosts, 0)
	local lateral = difference:Dot(goal.right)
	local depth = difference:Dot(goal.field)
	-- Der Boundary Guard entfernt nur die Komponente, die aus der erlaubten
	-- Keeperfläche herausführt. Bewegung entlang der Linie bleibt möglich.
	if keeperLocal.X <= minX + CONFIG.ZoneBoundaryGuardDistance and lateral < 0 then lateral = 0 end
	if keeperLocal.X >= maxX - CONFIG.ZoneBoundaryGuardDistance and lateral > 0 then lateral = 0 end
	if keeperLocal.Z <= minDepth + CONFIG.ZoneBoundaryGuardDistance and depth < 0 then depth = 0 end
	if keeperLocal.Z >= maxDepth - CONFIG.ZoneBoundaryGuardDistance and depth > 0 then depth = 0 end
	difference = goal.right * lateral + goal.field * depth
	local distance = difference.Magnitude
	if Runtime.TargetArrived then
		if distance <= CONFIG.ArrivalExitDistance then
			Runtime.ForcedMoveVector = Vector3.zero
			Runtime.ForcedMoveOwner = "BOT"
			return
		end
		Runtime.TargetArrived = false
	end
	if distance <= CONFIG.ArrivalEnterDistance then
		Runtime.TargetArrived = true
		Runtime.ForcedMoveVector = Vector3.zero
	else
		local strength = math.clamp(distance / CONFIG.FullInputDistance, 0, 1)
		local desired = safeUnit(difference)
		local closingSpeed = math.max(0, Runtime.LastKeeperVelocity:Dot(desired))
		local stoppingDistance = closingSpeed * closingSpeed / (2 * math.max(Runtime.RunAcceleration, 1))
		if stoppingDistance > distance then
			strength *= math.clamp(distance / math.max(stoppingDistance, 0.05), 0.12, 1)
		end
		Runtime.ForcedMoveVector = worldToMoveVector(difference, strength)
	end
	Runtime.ForcedMoveOwner = "BOT"
	-- Ein verankerter Chickynoid-Root reagiert nicht auf Humanoid:Move. Deshalb
	-- ist dieser Fallback ausschließlich für normale Roblox-Characters erlaubt.
	local hookRecentlyRead = os.clock() - Runtime.LastControlHookRead <= CONFIG.ControlRepairInterval * 1.4
	if Runtime.HookCount == 0 or not hookRecentlyRead or os.clock() < Runtime.HumanoidFallbackUntil then
		local character = getCharacterModel(LocalPlayer)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not Runtime.ChickynoidDetected then
			humanoid:Move(Runtime.ForcedMoveVector, true)
			Runtime.MovementDriver = Runtime.HookCount > 0 and "HOOK + HUMANOID" or "HUMANOID FALLBACK"
		else
			Runtime.MovementDriver = "CHICKYNOID HOOK WAIT"
		end
	else
		Runtime.MovementDriver = "CONTROLMODULE"
	end
end)

local function updateKeeperLearning(now, keeper)
	if not Runtime.LastKeeperPosition then
		Runtime.LastKeeperPosition, Runtime.LastKeeperSample = keeper, now
		return
	end
	local dt = now - Runtime.LastKeeperSample
	if dt < 0.07 then return end
	local displacement = horizontal(keeper - Runtime.LastKeeperPosition)
	local velocity = displacement / dt
	local learningLocked = now < Runtime.InputLearningPausedUntil
		or Runtime.SavePhase == "DIVE_ACTIVE"
		or Runtime.SavePhase == "CONTACT_WINDOW"
		or Runtime.SavePhase == "GETTING_UP"
	if learningLocked then
		Runtime.LastKeeperVelocity = velocity
		Runtime.LastKeeperPosition, Runtime.LastKeeperSample = keeper, now
		return
	end
	if Runtime.WorldTarget and not Runtime.Diving then
		local targetDirection = safeUnit(horizontal(Runtime.WorldTarget - Runtime.LastKeeperPosition))
		local targetDistance = horizontal(Runtime.WorldTarget - Runtime.LastKeeperPosition).Magnitude
		local directedSpeedRaw = velocity:Dot(targetDirection)
		local inputActive = Runtime.ForcedMoveOwner == "BOT"
			and Runtime.ForcedMoveVector
			and Runtime.ForcedMoveVector.Magnitude >= 0.45
		if inputActive and targetDistance > CONFIG.ArrivalExitDistance
			and displacement.Magnitude >= CONFIG.WrongDirectionMinimumTravel then
			local alignment = safeUnit(displacement):Dot(targetDirection)
			if Runtime.InputCalibrationState == "PENDING" then
				if alignment <= CONFIG.WrongDirectionMaximumAlignment then
					Runtime.WrongDirectionSamples += 1
					Runtime.CorrectDirectionSamples = 0
				elseif alignment >= CONFIG.CorrectDirectionMinimumAlignment then
					Runtime.CorrectDirectionSamples += 1
					Runtime.WrongDirectionSamples = 0
				end
				if Runtime.WrongDirectionSamples >= CONFIG.WrongDirectionConfirmations then
					Runtime.InputPolarity = -Runtime.InputPolarity
					Runtime.WrongDirectionSamples = 0
					Runtime.CorrectDirectionSamples = 0
					Runtime.InputCalibrationState = "LOCKED"
					Runtime.TargetArrived = false
					Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
					Runtime.Event = "INPUT LOCKED REVERSED"
				elseif Runtime.CorrectDirectionSamples >= CONFIG.CorrectDirectionConfirmations then
					Runtime.WrongDirectionSamples = 0
					Runtime.CorrectDirectionSamples = 0
					Runtime.InputCalibrationState = "LOCKED"
					Runtime.Event = "INPUT LOCKED STANDARD"
				end
			elseif Runtime.InputCalibrationState == "LOCKED" then
				if alignment <= CONFIG.WrongDirectionMaximumAlignment then
					Runtime.WrongDirectionSamples += 1
				elseif alignment >= CONFIG.CorrectDirectionMinimumAlignment then
					Runtime.WrongDirectionSamples = 0
				end
				if Runtime.WrongDirectionSamples >= CONFIG.LockedWrongDirectionConfirmations then
					Runtime.InputCalibrationState = "FAILED"
					Runtime.WorldTarget = nil
					Runtime.ForcedMoveVector = Vector3.zero
					Runtime.ForcedMoveOwner = "BOT"
					Runtime.Event = "INPUT DIRECTION FAILED - RECAL"
				end
			end
		end
		local directedSpeed = math.max(0, directedSpeedRaw)
		if directedSpeed > 0.5 then
			Runtime.RunSpeed = lerp(Runtime.RunSpeed, math.clamp(directedSpeed, CONFIG.MinimumRunSpeed, CONFIG.MaximumRunSpeed), CONFIG.LearnAlpha)
			local acceleration = math.abs(directedSpeed - math.max(0, Runtime.LastKeeperVelocity:Dot(targetDirection))) / dt
			Runtime.RunAcceleration = lerp(Runtime.RunAcceleration, math.clamp(acceleration, CONFIG.MinimumRunAcceleration, CONFIG.MaximumRunAcceleration), CONFIG.LearnAlpha * 0.5)
		end
	end
	Runtime.LastKeeperVelocity = velocity
	Runtime.LastKeeperPosition, Runtime.LastKeeperSample = keeper, now
end

local function updateMovementHealth(now, keeper)
	local healthLocked = now < Runtime.InputLearningPausedUntil
		or Runtime.SavePhase == "DIVE_ACTIVE"
		or Runtime.SavePhase == "CONTACT_WINDOW"
		or Runtime.SavePhase == "GETTING_UP"
	if not Options.Bot or Runtime.HoldingBall or Runtime.Diving or healthLocked or not Runtime.WorldTarget then
		Runtime.LastMovementHealthPosition = keeper
		Runtime.LastMovementHealthCheck = now
		return
	end
	if not Runtime.LastMovementHealthPosition then
		Runtime.LastMovementHealthPosition = keeper
		Runtime.LastMovementHealthCheck = now
		return
	end
	if now - Runtime.LastMovementHealthCheck < CONFIG.MovementStuckCheckTime then return end
	local goal = Runtime.DefendedGoal
	if not goal then return end
	local safeTarget = clampSafeTarget(goal, Runtime.WorldTarget, Runtime.AllowOutsidePosts)
	Runtime.WorldTarget = safeTarget
	local targetDistance = horizontal(safeTarget - keeper).Magnitude
	local progress = horizontal(keeper - Runtime.LastMovementHealthPosition).Magnitude
	local inputActive = Runtime.ForcedMoveOwner == "BOT" and Runtime.ForcedMoveVector and Runtime.ForcedMoveVector.Magnitude > 0.2
	if inputActive and targetDistance >= CONFIG.MovementStuckMinDistance and progress < CONFIG.MovementStuckMinProgress then
		Runtime.BoundaryStuckCount += 1
		local keeperLocal = goalToLocal(goal, keeper)
		local minX, maxX, minDepth, maxDepth = getGoalMovementBounds(goal, Runtime.AllowOutsidePosts, 0)
		local nearBoundary = keeperLocal.X <= minX + CONFIG.ZoneBoundaryGuardDistance * 2
			or keeperLocal.X >= maxX - CONFIG.ZoneBoundaryGuardDistance * 2
			or keeperLocal.Z <= minDepth + CONFIG.ZoneBoundaryGuardDistance * 2
			or keeperLocal.Z >= maxDepth - CONFIG.ZoneBoundaryGuardDistance * 2
		if nearBoundary and Runtime.BoundaryStuckCount >= CONFIG.BoundaryStuckChecks then
			local retreat = clampSafeTarget(goal, keeper, false, CONFIG.ZoneBoundaryRetreatInset)
			if horizontal(retreat - keeper).Magnitude < CONFIG.ArrivalEnterDistance then
				retreat = clampSafeTarget(goal, goalToWorld(goal, 0, goal.homeDepth, goal.bottomY), false, 0)
			end
			Runtime.BoundaryRetreatTarget = retreat
			Runtime.BoundaryRetreatUntil = now + CONFIG.BoundaryRetreatTime
			Runtime.WorldTarget = retreat
			Runtime.TargetArrived = false
			Runtime.ForcedMoveVector = Vector3.zero
			Runtime.BoundaryStuckCount = 0
			Runtime.Event = "BOUNDARY TARGET REJECTED"
		elseif not nearBoundary and now - Runtime.LastMovementRepair >= CONFIG.MovementRepairCooldown then
			Runtime.LastMovementRepair = now
			Runtime.MovementRepairs += 1
			Runtime.HumanoidFallbackUntil = now + 1.25
			Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
			resolveModulesAndHooks()
			Runtime.Event = "MOVEMENT HOOK REPAIR " .. Runtime.MovementRepairs
		end
	else
		Runtime.BoundaryStuckCount = 0
	end
	Runtime.LastMovementHealthPosition = keeper
	Runtime.LastMovementHealthCheck = now
end

local function reachableRunDistance(time, direction)
	local usable = math.max(0, time - CONFIG.ReactionLatency)
	local acceleration, maximumSpeed = Runtime.RunAcceleration, Runtime.RunSpeed
	local projectedVelocity = direction and Runtime.LastKeeperVelocity:Dot(direction) or 0
	local initialSpeed = math.clamp(projectedVelocity, -maximumSpeed, maximumSpeed)
	local directionDelay = initialSpeed < -0.5 and CONFIG.RunDirectionChangePenalty or 0
	usable = math.max(0, usable - directionDelay)
	initialSpeed = math.max(0, initialSpeed)
	local accelerateTime = math.max(0, (maximumSpeed - initialSpeed) / math.max(acceleration, 0.01))
	if usable <= accelerateTime then return initialSpeed * usable + 0.5 * acceleration * usable * usable end
	local accelerationDistance = initialSpeed * accelerateTime + 0.5 * acceleration * accelerateTime * accelerateTime
	return accelerationDistance + maximumSpeed * (usable - accelerateTime)
end

local function timeToRunDistance(distance, direction, depthDelta)
	distance = math.max(0, distance)
	if distance <= 0.001 then return CONFIG.ReactionLatency end
	local low, high = 0, CONFIG.MaximumPredictionTime
	for _ = 1, 12 do
		local middle = (low + high) * 0.5
		if reachableRunDistance(middle, direction) >= distance then high = middle else low = middle end
	end
	return high + math.abs(depthDelta or 0) * CONFIG.RunDepthPenaltyScale
end

local function catchRadiusAtHeight(goal, worldY)
	local relativeHeight = (worldY - goal.bottomY) / math.max(goal.topY - goal.bottomY, 1)
	-- Extreme Boden-/Hochkontakte besitzen weniger seitliche Körperabdeckung.
	-- Die Reduktion bleibt klein, weil die echte Fanghitbox serverseitig ist.
	local heightScale = 1
	if relativeHeight < 0.12 then
		heightScale = lerp(0.88, 1, clamp01(relativeHeight / 0.12))
	elseif relativeHeight > CONFIG.HighBallRelative then
		heightScale = lerp(1, 0.86, clamp01((relativeHeight - CONFIG.HighBallRelative) / math.max(1 - CONFIG.HighBallRelative, 0.01)))
	end
	return CONFIG.PredictedCatchRadius * heightScale, relativeHeight
end

--==============================================================
-- NATIVER GRAB-MANAGER AUS DEM FUNKTIONIERENDEN V20-PFAD
--==============================================================

local GrabImages = {}
local LastGrabIndicatorRefresh = -100

local function isGreen(color)
	return color.G > color.R + 0.11 and color.G > color.B + 0.025
end

local function refreshGrabIndicators()
	GrabImages = {}
	local mobile = PlayerGui:FindFirstChild("MobileGui")
	local exactButton = mobile and mobile:FindFirstChild("GoalkeeperGrab", true)
	local exactIcon = exactButton and exactButton:FindFirstChild("Icon", true)
	if exactIcon and (exactIcon:IsA("ImageLabel") or exactIcon:IsA("ImageButton")) then table.insert(GrabImages, exactIcon) end
	for _, object in ipairs(PlayerGui:GetDescendants()) do
		if object.Name == "GoalkeeperGrab" then
			for _, child in ipairs(object:GetDescendants()) do
				if child.Name == "Icon" and (child:IsA("ImageLabel") or child:IsA("ImageButton")) then
					if not table.find(GrabImages, child) then table.insert(GrabImages, child) end
				end
			end
		end
	end
	LastGrabIndicatorRefresh = os.clock()
end

local GRAB_TRUE_NAMES = {"GoalkeeperGrabbable", "GoalieGrabbable", "CanGoalieGrab", "CanGrab", "Grabbable"}
local HOLD_TRUE_NAMES = {"HoldingBall", "HasBall", "GoalieHoldingBall"}

local function hasTrueState(object, names, recursive)
	if not object then return false end
	for _, name in ipairs(names) do
		if object:GetAttribute(name) == true then return true end
		local value = object:FindFirstChild(name, recursive == true)
		if value and value:IsA("BoolValue") and value.Value == true then return true end
	end
	return false
end

local function getBallSignalRoot()
	local ball = Tracker.Ball
	if not ball then return nil end
	local current, best = ball, ball
	for _ = 1, 4 do
		current = current.Parent
		if not current or current == Workspace then break end
		if ballNameBonus(current.Name) > 0 then best = current end
	end
	return best
end

local function userIdFromValue(value)
	if typeof(value) == "number" then return math.floor(value + 0.5) end
	if typeof(value) == "string" then return tonumber(value) end
	if typeof(value) == "Instance" and value:IsA("Player") then return value.UserId end
	return nil
end

local function getReplicatedBallState()
	local ball = Tracker.Ball
	if not ball then return nil, false, false end
	local ownerId, locked, stored = nil, false, false
	local current = ball
	for _ = 1, 5 do
		if not current or current == Workspace then break end
		for _, attributeName in ipairs({"UserId", "player", "Player", "OwnerUserId", "PlayerId"}) do
			ownerId = ownerId or userIdFromValue(current:GetAttribute(attributeName))
		end
		locked = locked or current:GetAttribute("Locked") == true
		stored = stored or current:GetAttribute("Stored") == true
		current = current.Parent
	end
	return ownerId, locked, stored
end

local function isNativeGrabbable(keeper)
	Runtime.BallInRange = false
	if Runtime.Diving or Runtime.SavePhase == "DIVE_ACTIVE" then
		return false, "DIVE ACTIVE"
	end
	local dataset, model = Tracker.Dataset, Tracker.DatasetModel
	if dataset and Runtime.Auxillary and typeof(Runtime.Auxillary.GoalkeeperGrabbable) == "function" then
		local ok, ready = pcall(Runtime.Auxillary.GoalkeeperGrabbable, LocalPlayer, dataset)
		if ok and ready == true then return true, "AUX KEEPER ATTRIBUTE" end
	end
	if model and Runtime.ClientBall and typeof(Runtime.ClientBall.BallInRange) == "function" then
		local ok, inRange = pcall(Runtime.ClientBall.BallInRange, model)
		Runtime.BallInRange = ok and inRange == true
		if Runtime.BallInRange then return true, "CLIENTBALL IN RANGE" end
	end
	if os.clock() - LastGrabIndicatorRefresh >= CONFIG.GrabIndicatorRefresh then refreshGrabIndicators() end
	for _, image in ipairs(GrabImages) do
		if image.Parent and isGreen(image.ImageColor3) then return true, "GREEN UI" end
	end
	local root = getBallSignalRoot()
	if root then
		for _, object in ipairs(root:GetDescendants()) do
			if object:IsA("Highlight") and (isGreen(object.FillColor) or isGreen(object.OutlineColor)) then return true, "HIGHLIGHT" end
		end
		if hasTrueState(root, GRAB_TRUE_NAMES, true) or hasTrueState(Tracker.Ball, GRAB_TRUE_NAMES, false) then
			return true, "ATTRIBUTE"
		end
	end
	-- Letzter Fallback nur bei realem Kontakt mit der existierenden GoalieGrab-
	-- Box. Eine große Zentrumdistanz allein gilt nicht mehr als Fangfreigabe.
	if keeper and Tracker.Position then
		local relativeSpeed = horizontal(Tracker.Velocity - getKeeperVelocity()).Magnitude
		local allowedSpeed = Runtime.Diving and CONFIG.DiveGrabFallbackMaxRelativeSpeed or CONFIG.GrabPhysicalFallbackMaxRelativeSpeed
		local grabHitbox = getGoalieGrabHitbox()
		local ballPart = Tracker.PhysicsBall or Tracker.Ball
		local ballRadius = 0.675
		if ballPart and ballPart:IsA("BasePart") then
			ballRadius = math.max(ballPart.Size.X, ballPart.Size.Y, ballPart.Size.Z) * 0.5
		end
		local hitboxReady = grabHitbox
			and distanceToOrientedBox(Tracker.Position, grabHitbox) <= ballRadius + CONFIG.GoalieGrabHitboxPadding
		if hitboxReady and relativeSpeed <= allowedSpeed then return true, "GOALIEGRAB CONTACT" end
	end
	return false, "NONE"
end

local function predictGrabPreparation(keeper)
	if not keeper or not Tracker.Position or Runtime.Diving or Runtime.SavePhase == "DIVE_ACTIVE" then return nil end
	local keeperVelocity = getKeeperVelocity()
	local bestTime, bestPosition, bestDistance = nil, nil, math.huge
	for t = CONFIG.GrabPrepareMinimumTime, CONFIG.GrabPrepareMaximumTime, 0.015 do
		local ballPosition = predictBallAt(t)
		if ballPosition then
			local keeperPosition = keeper + keeperVelocity * t
			local distance = (ballPosition - keeperPosition).Magnitude
			if distance < bestDistance then bestTime, bestPosition, bestDistance = t, ballPosition, distance end
		end
	end
	if bestTime and bestDistance <= CONFIG.GrabPrepareMaximumDistance then
		return bestTime, bestPosition, bestDistance
	end
	return nil
end

local function confirmedHoldingBall(keeper)
	local character = LocalPlayer.Character
	local root = getBallSignalRoot()
	local gameState = ReplicatedStorage:FindFirstChild("GameState")
	local gamePlay = gameState and gameState:FindFirstChild("GamePlay")
	local goalieHoldingValue = gamePlay and gamePlay:FindFirstChild("GoalieHoldingBall")
	if goalieHoldingValue and goalieHoldingValue:IsA("ObjectValue") and goalieHoldingValue.Value then
		local holder = goalieHoldingValue.Value
		local holderIsLocal = holder == LocalPlayer or holder == character
			or (character and holder:IsDescendantOf(character))
			or holder:GetAttribute("UserId") == LocalPlayer.UserId
			or holder:GetAttribute("PlayerId") == LocalPlayer.UserId
		if holderIsLocal then return true end
	end
	local confirmedFlag = hasTrueState(LocalPlayer, HOLD_TRUE_NAMES, false)
		or hasTrueState(character, HOLD_TRUE_NAMES, true)
		or hasTrueState(root, HOLD_TRUE_NAMES, true)
	if not confirmedFlag then return false end
	if Tracker.Position and keeper and (Tracker.Position - keeper).Magnitude <= CONFIG.HoldingConfirmationDistance then return true end
	return os.clock() - Runtime.LastGrabAttempt <= CONFIG.GrabConfirmWindow and os.clock() - Runtime.LastBallNear <= CONFIG.GrabConfirmWindow
end

local function fireGrab(value)
	-- Der native Movement-Input ist der beste Weg: Er benutzt dieselbe interne
	-- Aufrufkette wie LeftControl/ButtonB und damit die richtigen Argumente fuer
	-- BallHandle/GoalieBallHandle, ohne deren unbekannte Signatur zu erraten.
	if Runtime.Movement then
		local methodName = value and "InputBegan" or "InputEnded"
		local method = Runtime.Movement[methodName]
		if typeof(method) == "function" then
			local ok = pcall(function()
				method({KeyCode = "GoalkeeperGrab"}, false)
			end)
			if ok then
				Runtime.GrabDriver = "NATIVE INPUT"
				return true
			end
		end
	end
	Runtime.GrabDriver = "UNAVAILABLE"
	return false
end

local function pressGrab(keeper)
	if not Options.AutoGrab or Runtime.HoldingBall or not Runtime.NativeGrab or not Tracker.Position or not keeper then return false end
	if Runtime.Diving or Runtime.SavePhase == "DIVE_ACTIVE" then
		Runtime.GrabFSM = "DIVE LOCK"
		return false
	end
	local distance = (Tracker.Position - keeper).Magnitude
	local grabHitbox = getGoalieGrabHitbox()
	local hitboxDistance = grabHitbox and distanceToOrientedBox(Tracker.Position, grabHitbox) or math.huge
	if distance > CONFIG.GrabSanityDistance and hitboxDistance > CONFIG.GoalieGrabHitboxPadding + 0.8 then return false end
	if os.clock() - Runtime.LastGrab < CONFIG.GrabCooldown then return false end
	Runtime.LastBallNear = os.clock()
	Runtime.LastGrab = os.clock()
	Runtime.LastGrabAttempt = os.clock()
	Runtime.GrabFSM = "PRESSED"
	if not fireGrab(true) then
		Runtime.GrabFSM = "WAIT"
		return false
	end
	-- Zweiter Versuch als echte neue Flanke (UP -> DOWN), nicht zweimal DOWN.
	-- So bleibt Auto-Grab dauerhaft aktiv, ohne den Movement-State zu besitzen.
	task.delay(CONFIG.GrabRetryDelay, function()
		if Gui.Parent and Options.AutoGrab and not Runtime.HoldingBall then
			fireGrab(false)
		end
	end)
	task.delay(CONFIG.GrabRetryDelay + 0.018, function()
		if Gui.Parent and Options.AutoGrab and not Runtime.HoldingBall then
			local ready = isNativeGrabbable(getKeeperPosition())
			if ready then fireGrab(true) end
		end
	end)
	task.delay(math.max(CONFIG.GrabReleaseDelay, CONFIG.GrabRetryDelay + 0.050), function()
		fireGrab(false)
		if Runtime.GrabFSM == "PRESSED" then Runtime.GrabFSM = "ARMED" end
	end)
	return true
end

--==============================================================
-- NATIVER DIVE: KEIN REMOTE, KEIN SetVelocity
--==============================================================

local function getNativeDiveVelocity()
	if not Runtime.Movement or typeof(Runtime.Movement.GetDiveVelocity) ~= "function" then return nil end
	local ok, result = pcall(Runtime.Movement.GetDiveVelocity)
	return ok and typeof(result) == "Vector3" and result or nil
end

local function getDiveTier(goal, worldY)
	local relativeHeight = clamp01((worldY - goal.bottomY) / math.max(goal.topY - goal.bottomY, 0.01))
	return relativeHeight >= CONFIG.HighBallRelative and "HIGH"
		or (relativeHeight <= CONFIG.LowBallRelative and "LOW" or "MID"), relativeHeight
end

local function getDiveProfile(side, tier)
	local key = (side < 0 and "LEFT_" or "RIGHT_") .. tier
	return Runtime.DiveProfiles[key], key
end

local function getDiveVerticalTolerance(tier)
	return tier == "HIGH" and CONFIG.DiveVerticalToleranceHigh
		or (tier == "LOW" and CONFIG.DiveVerticalToleranceLow or CONFIG.DiveVerticalToleranceMid)
end

local function selectDiveTier(goal, worldY, uncertainty, side)
	local height = math.max(0.01, goal.topY - goal.bottomY)
	local ratio = clamp01((worldY - goal.bottomY) / height)
	local spread = math.max(0, uncertainty or 0) / height
	local candidates = {}
	local function add(tier)
		if not table.find(candidates, tier) then table.insert(candidates, tier) end
	end
	add(getDiveTier(goal, worldY))
	if ratio - spread <= CONFIG.LowBallRelative and ratio + spread >= CONFIG.LowBallRelative then
		add("LOW")
		add("MID")
	end
	if ratio - spread <= CONFIG.HighBallRelative and ratio + spread >= CONFIG.HighBallRelative then
		add("MID")
		add("HIGH")
	end
	local bestTier, bestScore = candidates[1], -math.huge
	for _, tier in ipairs(candidates) do
		local profile = getDiveProfile(side, tier)
		local confidence = profile and clamp01(profile.samples / 6) or 0
		local centerRatio = tier == "HIGH" and 0.82 or (tier == "LOW" and 0.18 or 0.50)
		local heightScore = -math.abs(ratio - centerRatio) * CONFIG.DiveTierHeightScoreWeight
		local reachRatio = (profile and profile.reach or CONFIG.DefaultDiveReach) / math.max(CONFIG.DefaultDiveReach, 0.01)
		local reachScore = reachRatio * lerp(0.90, 1, confidence) * CONFIG.DiveTierReachScoreWeight
		local score = heightScore + reachScore
			- (profile and profile.contact or CONFIG.DefaultDiveContactTime) * 0.04
		if score > bestScore then bestTier, bestScore = tier, score end
	end
	return bestTier
end

local function chooseDiveInput(desiredWorldDirection, tier)
	local oldVector, oldOwner = Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner
	local bestInput, bestVelocity, bestScore = nil, nil, -math.huge
	local verticalInput = (tier == "HIGH" and -1 or (tier == "LOW" and 1 or 0))
		* Runtime.DiveVerticalInputPolarity
	for _, horizontalInput in ipairs({-1, -0.75, -0.50, -0.25, 0.25, 0.50, 0.75, 1}) do
		local candidate = Vector3.new(horizontalInput, 0, verticalInput)
		Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = candidate, "DIVE_TEST"
		local diveVelocity = getNativeDiveVelocity()
		if diveVelocity and horizontal(diveVelocity).Magnitude > 0.01 then
			local alignment = safeUnit(horizontal(diveVelocity)):Dot(safeUnit(horizontal(desiredWorldDirection)))
			local speedConfidence = clamp01(horizontal(diveVelocity).Magnitude / math.max(CONFIG.MinimumDiveReach, 0.01))
			local score = alignment * 0.92 + speedConfidence * 0.08
			if score > bestScore then bestInput, bestVelocity, bestScore = candidate, diveVelocity, score end
		end
	end
	Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = oldVector, oldOwner
	local fallback = worldToMoveVector(desiredWorldDirection, 1)
	local fallbackX = math.abs(fallback.X) >= 0.10 and math.clamp(fallback.X, -1, 1) or sign(fallback.X)
	if fallbackX == 0 then fallbackX = 1 end
	return bestInput or Vector3.new(fallbackX, 0, verticalInput), bestVelocity
end

local function performDive(goal, side, reason, interceptY, tierOverride)
	local now = os.clock()
	if not Options.AutoDive or Runtime.HoldingBall or Runtime.Diving or now - Runtime.LastDive < CONFIG.DiveCooldown then return false end
	if not Runtime.Movement or typeof(Runtime.Movement.InputBegan) ~= "function" then return false end
	-- Das Laufziel darf den nativen Dive in keinem Frame überschreiben.
	clearWorldTarget()
	local desiredWorld = goal.right * side
	local tier = tierOverride or (interceptY and getDiveTier(goal, interceptY) or "MID")
	local _, profileKey = getDiveProfile(side, tier)
	local diveStart = getKeeperPosition()
	local startHitbox = getGoalieGrabHitbox()
	local startHitboxOffsetY = diveStart and startHitbox and (startHitbox.Position.Y - diveStart.Y) or nil
	local input = chooseDiveInput(desiredWorld, tier)
	Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = input, "DIVE"
	setSavePhase("DIVE_COMMITTED", "DIVE COMMIT " .. (side < 0 and "LEFT" or "RIGHT") .. " " .. tier)
	local ok = pcall(function() Runtime.Movement.InputBegan({KeyCode = "SlideTackle"}, false) end)
	if not ok then
		Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
		setSavePhase("SHOT_TRACKING", "NATIVE DIVE INPUT FAILED")
		return false
	end
	Runtime.Diving = true
	Runtime.DiveToken += 1
	Runtime.DiveStartTime = now
	Runtime.DiveMinimumEndAt = now + CONFIG.DiveMinimumActiveTime
	Runtime.DiveMaximumEndAt = now + CONFIG.DiveMaximumActiveTime
	Runtime.DiveStillSince = nil
	Runtime.DiveFirstMotionAt = nil
	Runtime.DiveMotionSamples = {}
	Runtime.DiveContactDetected = false
	Runtime.DiveContactKind = "NONE"
	Runtime.DiveContactPosition = nil
	Runtime.DivePreviousBallVelocity = Tracker.Velocity
	Runtime.DiveExpectedImpactAt = Runtime.BallETA < math.huge and now + Runtime.BallETA or 0
	Runtime.ContactWindowUntil = 0
	Runtime.GetUpEarliest = 0
	Runtime.GetUpDeadline = 0
	Runtime.RecoveryRequired = true
	Runtime.RecoveryReason = "POST-DIVE"
	Runtime.InputLearningPausedUntil = Runtime.DiveMaximumEndAt + CONFIG.GetUpMaximumTime + 0.20
	Runtime.LastDive = now
	Runtime.DivedTrajectoryId = Runtime.TrajectoryId
	Runtime.DiveStart = diveStart or getKeeperPosition()
	Runtime.DiveMaximum = 0
	Runtime.ActiveDiveProfile = profileKey
	Runtime.DiveDirectionName = (side < 0 and "LEFT " or "RIGHT ") .. tier
	Runtime.DiveCommandedTier = tier
	Runtime.DiveStartHitboxOffsetY = startHitboxOffsetY
	Runtime.DiveHitboxPeakDelta = -math.huge
	Runtime.DiveHitboxTroughDelta = math.huge
	Runtime.DiveHitboxBinsThisDive = {}
	Runtime.DiveHitboxSampleCount = 0
	setSavePhase("DIVE_ACTIVE", "NATIVE DIVE " .. Runtime.DiveDirectionName .. " / " .. reason)
	-- Ausschließlich der native Movement-Pfad steuert Animation, ActionState
	-- und Servervalidierung. Es gibt keinen eigenen Dive-/Hitbox-Remote mehr.
	local token = Runtime.DiveToken
	task.delay(CONFIG.DiveInputHold, function()
		if token == Runtime.DiveToken and Runtime.ForcedMoveOwner == "DIVE" then Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil end
	end)
	return true
end

local function sampleDiveHitbox(now)
	local goal = Runtime.DefendedGoal
	local profile = Runtime.ActiveDiveProfile and Runtime.DiveProfiles[Runtime.ActiveDiveProfile]
	local hitbox = getGoalieGrabHitbox()
	if not goal or not profile or not hitbox or not Runtime.DiveStart then return end
	local elapsed = math.max(0, now - Runtime.DiveStartTime)
	local bin = math.floor(elapsed / CONFIG.DiveHitboxSampleStep + 0.5)
	if Runtime.DiveHitboxBinsThisDive[bin] then return end
	Runtime.DiveHitboxBinsThisDive[bin] = true
	Runtime.DiveHitboxSampleCount += 1

	local side = string.find(Runtime.ActiveDiveProfile, "LEFT_", 1, true) == 1 and -1 or 1
	local offset = hitbox.Position - Runtime.DiveStart
	local sample = {
		time = elapsed,
		lateral = offset:Dot(goal.right) * side,
		vertical = offset.Y,
		depth = offset:Dot(goal.field),
		extentLateral = math.min(CONFIG.DiveHitboxMaximumExtent, orientedBoxExtent(hitbox, goal.right)),
		extentVertical = math.min(CONFIG.DiveHitboxMaximumExtent, orientedBoxExtent(hitbox, Vector3.yAxis)),
		extentDepth = math.min(CONFIG.DiveHitboxMaximumExtent, orientedBoxExtent(hitbox, goal.field)),
	}
	profile.hitboxTimeline = profile.hitboxTimeline or {}
	local old = profile.hitboxTimeline[bin]
	if old then
		local alpha = CONFIG.DiveHitboxLearnAlpha
		old.time = lerp(old.time, sample.time, alpha)
		old.lateral = lerp(old.lateral, sample.lateral, alpha)
		old.vertical = lerp(old.vertical, sample.vertical, alpha)
		old.depth = lerp(old.depth, sample.depth, alpha)
		old.extentLateral = lerp(old.extentLateral, sample.extentLateral, alpha)
		old.extentVertical = lerp(old.extentVertical, sample.extentVertical, alpha)
		old.extentDepth = lerp(old.extentDepth, sample.extentDepth, alpha)
		old.observations = (old.observations or 1) + 1
	else
		sample.observations = 1
		profile.hitboxTimeline[bin] = sample
		profile.hitboxBinCount = (profile.hitboxBinCount or 0) + 1
	end

	if Runtime.DiveStartHitboxOffsetY ~= nil then
		local deltaY = (hitbox.Position.Y - Runtime.DiveStart.Y) - Runtime.DiveStartHitboxOffsetY
		Runtime.DiveHitboxPeakDelta = math.max(Runtime.DiveHitboxPeakDelta, deltaY)
		Runtime.DiveHitboxTroughDelta = math.min(Runtime.DiveHitboxTroughDelta, deltaY)
	end
end

local function finalizeDiveHitboxCalibration()
	if Runtime.DiveHitboxCalibrationToken == Runtime.DiveToken then return false end
	Runtime.DiveHitboxCalibrationToken = Runtime.DiveToken
	local profile = Runtime.ActiveDiveProfile and Runtime.DiveProfiles[Runtime.ActiveDiveProfile]
	if profile and Runtime.DiveHitboxSampleCount >= CONFIG.DiveHitboxMinimumBins then
		profile.hitboxDives = (profile.hitboxDives or 0) + 1
	end
	local tier = Runtime.DiveCommandedTier
	local threshold = CONFIG.DiveVerticalPolarityThreshold
	local clearlyLow = Runtime.DiveHitboxPeakDelta < threshold
		and Runtime.DiveHitboxTroughDelta <= -threshold
	local clearlyHigh = Runtime.DiveHitboxTroughDelta > -threshold
		and Runtime.DiveHitboxPeakDelta >= threshold
	if (tier == "HIGH" and clearlyLow) or (tier == "LOW" and clearlyHigh) then
		Runtime.DiveVerticalInputPolarity *= -1
		if profile then
			profile.hitboxTimeline = {}
			profile.hitboxDives = 0
			profile.hitboxBinCount = 0
		end
		Runtime.Event = "DIVE HEIGHT INPUT POLARITY CORRECTED"
		return true
	end
	return false
end

local function updateDiveLearning(keeper)
	if Runtime.Diving and Runtime.DiveStart and Runtime.DefendedGoal then
		local displacement = math.abs((keeper - Runtime.DiveStart):Dot(Runtime.DefendedGoal.right))
		Runtime.DiveMaximum = math.max(Runtime.DiveMaximum, displacement)
		local now = os.clock()
		sampleDiveHitbox(now)
		if not Runtime.DiveFirstMotionAt and displacement >= CONFIG.DiveMotionStartDistance then
			Runtime.DiveFirstMotionAt = now
		end
		table.insert(Runtime.DiveMotionSamples, {time = now, distance = displacement})
		if #Runtime.DiveMotionSamples > CONFIG.DiveMaximumMotionSamples then
			table.remove(Runtime.DiveMotionSamples, 1)
		end
	end
end

local function measuredDiveTravelTime(fraction)
	if Runtime.DiveMaximum <= 0 or #Runtime.DiveMotionSamples == 0 then return nil end
	local targetDistance = Runtime.DiveMaximum * fraction
	local motionStart = Runtime.DiveFirstMotionAt or Runtime.DiveStartTime
	for _, sample in ipairs(Runtime.DiveMotionSamples) do
		if sample.distance >= targetDistance then return math.max(0.015, sample.time - motionStart) end
	end
	return nil
end

local function finishDiveMotion(now, reason)
	if not Runtime.Diving then return end
	if finalizeDiveHitboxCalibration() then Runtime.DiveMaximum = 0 end
	Runtime.Diving = false
	if Runtime.ForcedMoveOwner == "DIVE" then
		Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
	end
	-- Nur eine wirklich gemessene Seitbewegung darf das Reichweitenmodell
	-- verändern. Ein vom Server abgelehnter Dive darf es nicht verschlechtern.
	if Runtime.DiveMaximum >= CONFIG.MinimumDiveReach * 0.35 then
		local learned = math.clamp(Runtime.DiveMaximum, CONFIG.MinimumDiveReach, CONFIG.MaximumDiveReach)
		local profile = Runtime.ActiveDiveProfile and Runtime.DiveProfiles[Runtime.ActiveDiveProfile]
		if profile then
			profile.reach = lerp(profile.reach, learned, CONFIG.DiveLearnAlpha)
			if Runtime.DiveFirstMotionAt then
				local measuredWindup = math.clamp(Runtime.DiveFirstMotionAt - Runtime.DiveStartTime, 0.025, 0.22)
				profile.windup = lerp(profile.windup or 0.09, measuredWindup, CONFIG.DiveLearnAlpha)
			end
			for _, checkpoint in ipairs({
				{field = "t25", fraction = 0.25},
				{field = "t50", fraction = 0.50},
				{field = "t75", fraction = 0.75},
				{field = "t100", fraction = 0.98},
			}) do
				local measured = measuredDiveTravelTime(checkpoint.fraction)
				if measured then
					profile[checkpoint.field] = lerp(profile[checkpoint.field] or measured, measured, CONFIG.DiveLearnAlpha)
				end
			end
			profile.t50 = math.max(profile.t25, profile.t50)
			profile.t75 = math.max(profile.t50, profile.t75)
			profile.t100 = math.max(profile.t75, profile.t100)
			profile.samples += 1
		end
		if Runtime.ActiveDiveProfile and string.find(Runtime.ActiveDiveProfile, "LEFT_", 1, true) == 1 then
			Runtime.DiveReachLeft = lerp(Runtime.DiveReachLeft, learned, CONFIG.DiveLearnAlpha)
		else
			Runtime.DiveReachRight = lerp(Runtime.DiveReachRight, learned, CONFIG.DiveLearnAlpha)
		end
	end
	Runtime.ContactWindowUntil = now + CONFIG.DiveContactWindowTime
	Runtime.GetUpEarliest = Runtime.ContactWindowUntil + CONFIG.GetUpMinimumTime
	Runtime.GetUpDeadline = Runtime.ContactWindowUntil + CONFIG.GetUpMaximumTime
	Runtime.InputLearningPausedUntil = Runtime.GetUpDeadline + 0.20
	setSavePhase("CONTACT_WINDOW", reason)
end

local function updateDiveLifecycle(now, keeper)
	local keeperSpeed = horizontal(Runtime.LastKeeperVelocity).Magnitude
	if Runtime.Diving then
		updateDiveLearning(keeper)
		if now >= Runtime.DiveMinimumEndAt then
			if keeperSpeed <= CONFIG.DiveMotionStopSpeed then
				Runtime.DiveStillSince = Runtime.DiveStillSince or now
			else
				Runtime.DiveStillSince = nil
			end
			local motionStopped = Runtime.DiveStillSince
				and now - Runtime.DiveStillSince >= CONFIG.DiveMotionStopConfirmTime
			if motionStopped or now >= Runtime.DiveMaximumEndAt then
				finishDiveMotion(now, motionStopped and "DIVE MOTION COMPLETE" or "DIVE TIMEOUT SAFE")
			end
		end
		return
	end
	if Runtime.SavePhase == "CONTACT_WINDOW" and now >= Runtime.ContactWindowUntil then
		setSavePhase("GETTING_UP", Runtime.DiveContactDetected and "CONTACT CONFIRMED" or "POST-DIVE GET UP")
	end
	if Runtime.SavePhase == "GETTING_UP" then
		local readyByMotion = now >= Runtime.GetUpEarliest and keeperSpeed <= CONFIG.RecoverySettleSpeed
		if readyByMotion or now >= Runtime.GetUpDeadline then
			Runtime.RecoveryRequired = true
			Runtime.RecoveryReason = Runtime.DiveContactDetected and "POST-SAVE" or "POST-DIVE"
			setSavePhase("RECOVER_TO_ZONE", readyByMotion and "CONTROL RETURNED" or "GET-UP TIMEOUT")
		end
	end
end

--==============================================================
-- KEEPER-POSITIONEN UND DETERMINISTISCHE SAVE-ENTSCHEIDUNG
--==============================================================

local function homeTarget(goal, ballPosition)
	local ballLocal = goalToLocal(goal, ballPosition)
	local depthDenominator = math.max(ballLocal.Z, goal.homeDepth + 0.5)
	local lateral = ballLocal.X * goal.homeDepth / depthDenominator
	-- Winkelhalbierende zum Ball, aber mit Post-Guard: Vor dem Schuss darf eine
	-- extreme Ballposition nie die komplette entfernte Ecke öffnen.
	local postGuard = math.min(goal.halfWidth - CONFIG.PostInsidePadding, goal.halfWidth * CONFIG.PositionPostGuardRatio)
	lateral = math.clamp(lateral, -postGuard, postGuard)
	return goalToWorld(goal, lateral, goal.homeDepth, goal.bottomY)
end

local function looseBallTarget(goal, ballPosition, allowOutsidePosts, keeperPosition)
	local ballLocal = goalToLocal(goal, ballPosition)
	local limit = allowOutsidePosts and goal.halfWidth + CONFIG.SaveOutsidePadding or goal.halfWidth - CONFIG.PostInsidePadding
	local lateral = math.clamp(ballLocal.X, -limit, limit)
	local depth = math.clamp(ballLocal.Z - CONFIG.ApproachBehindBall, CONFIG.GoalLineMinimumDepth, goal.maximumDepth)
	local approach = goalToWorld(goal, lateral, depth, goal.bottomY)
	if keeperPosition and horizontal(approach - keeperPosition).Magnitude <= CONFIG.SlowCollectStageDistance then
		depth = math.clamp(ballLocal.Z - 0.22, CONFIG.GoalLineMinimumDepth, goal.maximumDepth)
	end
	return goalToWorld(goal, lateral, depth, goal.bottomY)
end

local function postDiveRecoveryTarget(goal, keeper)
	local keeperLocal = goalToLocal(goal, keeper)
	local minX, maxX, minDepth, maxDepth = getGoalMovementBounds(goal, false, 0.20)
	local outsideSafeZone = keeperLocal.X < minX or keeperLocal.X > maxX
		or keeperLocal.Z < minDepth or keeperLocal.Z > maxDepth
	if outsideSafeZone then
		-- Kürzester Weg zum nächsten sicheren Punkt; nicht diagonal durch das
		-- ganze Tor zur Mitte laufen, solange der Keeper noch außerhalb liegt.
		return goalToWorld(
			goal,
			math.clamp(keeperLocal.X, minX, maxX),
			math.clamp(keeperLocal.Z, minDepth, maxDepth),
			goal.bottomY
		), true
	end
	return clampSafeTarget(goal, goalToWorld(goal, 0, goal.homeDepth, goal.bottomY), false, 0.20), false
end

local function updateLikelyPossessor(now)
	local ballPosition = Tracker.Position
	if not ballPosition then
		Runtime.Possessor = nil
		Runtime.PossessorConfidence = 0
		return nil
	end
	local replicatedOwnerId, ballLocked, ballStored = getReplicatedBallState()
	local best, bestScore = nil, 0
	for _, player in ipairs(Players:GetPlayers()) do
		local confirmedTeammate = player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
		if player ~= LocalPlayer and not confirmedTeammate then
			local root = getTrackedPlayerRoot(player)
			if root then
				local distance = (root.Position - ballPosition).Magnitude
				if distance <= CONFIG.PossessorSearchDistance then
					local toBall = safeUnit(ballPosition - root.Position)
					local facing = clamp01((root.CFrame.LookVector:Dot(toBall) + 1) * 0.5)
					local matchedMotion = 1 - clamp01((horizontal(root.AssemblyLinearVelocity - Tracker.Velocity)).Magnitude / 28)
					local holdingSignal = player:GetAttribute("HoldingBall") == true
						or (player.Character and player.Character:GetAttribute("HoldingBall") == true)
					local exactOwner = not ballStored and replicatedOwnerId ~= nil and replicatedOwnerId == player.UserId
					local score = (1 - distance / CONFIG.PossessorSearchDistance) * 42 + facing * 12 + matchedMotion * 14
					if exactOwner then score += 48 end
					if holdingSignal then score += 55 end
					if exactOwner and ballLocked then score += 8 end
					if player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team then score += 8 end
					if player == Runtime.Possessor then score += 8 end
					if score > bestScore then best, bestScore = player, score end
				end
			end
		end
	end
	if best and bestScore >= CONFIG.PossessorMinimumScore then
		if Runtime.PossessorStablePlayer ~= best then
			Runtime.PossessorStablePlayer = best
			Runtime.PossessorStableSince = now
		end
		Runtime.Possessor = best
		Runtime.PossessorUntil = now + CONFIG.PossessorMemoryTime
		Runtime.PossessorConfidence = clamp01((bestScore - CONFIG.PossessorMinimumScore) / math.max(100 - CONFIG.PossessorMinimumScore, 1))
	elseif now > Runtime.PossessorUntil then
		Runtime.Possessor = nil
		Runtime.PossessorConfidence = 0
		Runtime.PossessorStablePlayer = nil
		Runtime.PossessorStableSince = 0
	else
		Runtime.PossessorConfidence = math.max(0, Runtime.PossessorConfidence * 0.97)
	end
	return Runtime.Possessor
end

local function normalizedAnimationId(animationId)
	return tostring(animationId or ""):match("(%d+)$")
end

local function knownKickAnimationPlaying(player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then return false end
	local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
	if not ok then return false end
	for _, track in ipairs(tracks) do
		local animation = track.Animation
		local animationId = animation and normalizedAnimationId(animation.AnimationId)
		if animationId and CONFIG.KnownKickAnimations[animationId] then return true end
	end
	return false
end

local function clearPreShotIntent()
	Runtime.IntentPlayer = nil
	Runtime.IntentState = "IDLE"
	Runtime.IntentConfidence = 0
	Runtime.IntentAimX = nil
	Runtime.IntentAimY = nil
	Runtime.IntentEvidence = "NONE"
	Runtime.IntentStableSince = 0
	Runtime.IntentUntil = 0
	Runtime.IntentReleasePlayer = nil
	Runtime.IntentReleaseUntil = 0
end

local function updatePreShotIntent(goal, now, possessor)
	if not Options.PreShot or not goal or not Tracker.Position then
		clearPreShotIntent()
		return false
	end
	local goalwardSpeed = math.max(0, -Tracker.Velocity:Dot(goal.field))
	if Tracker.Velocity.Magnitude > CONFIG.PreShotMaximumBallSpeed
		or goalwardSpeed > CONFIG.PreShotMaximumGoalwardSpeed then
		-- Ab Ball-Release besitzt die gemessene Physik immer Vorrang.
		if now > Runtime.IntentReleaseUntil then clearPreShotIntent() end
		return false
	end
	if not possessor then
		if now <= Runtime.IntentUntil and Runtime.IntentAimX ~= nil then return true end
		clearPreShotIntent()
		return false
	end
	local root = getTrackedPlayerRoot(possessor)
	if not root then
		clearPreShotIntent()
		return false
	end
	local distance = (root.Position - Tracker.Position).Magnitude
	if distance > CONFIG.PreShotMaximumBallDistance then
		clearPreShotIntent()
		return false
	end

	if Runtime.IntentPlayer ~= possessor then
		Runtime.IntentPlayer = possessor
		Runtime.IntentStableSince = now
	end
	local ownerId, ballLocked, ballStored = getReplicatedBallState()
	local exactOwner = not ballStored and ownerId ~= nil and ownerId == possessor.UserId
	local holding = possessor:GetAttribute("HoldingBall") == true
		or (possessor.Character and possessor.Character:GetAttribute("HoldingBall") == true)
	local look = safeUnit(horizontal(root.CFrame.LookVector))
	local lookDepth = look:Dot(goal.field)
	local facingGoal = clamp01((-lookDepth - CONFIG.ShooterFacingMinimum) / math.max(1 - CONFIG.ShooterFacingMinimum, 0.01))
	local proximity = 1 - clamp01(distance / CONFIG.PreShotMaximumBallDistance)
	local stable = clamp01((now - Runtime.IntentStableSince) / CONFIG.PreShotStableTime)
	local kickAnimation = knownKickAnimationPlaying(possessor)
	local releaseSignal = Runtime.IntentReleasePlayer == possessor and now <= Runtime.IntentReleaseUntil
	if kickAnimation then
		Runtime.IntentReleasePlayer = possessor
		Runtime.IntentReleaseUntil = now + CONFIG.PreShotReleaseMemory
	end

	local confidence = proximity * 0.12 + facingGoal * 0.10 + stable * 0.08
	if exactOwner then confidence += 0.28 end
	if holding then confidence += 0.36 end
	if exactOwner and ballLocked then confidence += 0.06 end
	if kickAnimation or releaseSignal then confidence = math.max(confidence, 0.88) end
	confidence = clamp01(confidence)

	local evidence = {}
	if exactOwner then table.insert(evidence, "OWNER") end
	if holding then table.insert(evidence, "HOLD") end
	if ballLocked then table.insert(evidence, "LOCK") end
	if facingGoal > 0.25 then table.insert(evidence, "AIM") end
	if kickAnimation or releaseSignal then table.insert(evidence, "KICK-ANIM") end
	Runtime.IntentEvidence = #evidence > 0 and table.concat(evidence, "+") or "PROXIMITY"
	Runtime.IntentConfidence = confidence

	if lookDepth >= -CONFIG.ShooterFacingMinimum then
		Runtime.IntentState = confidence >= CONFIG.PreShotMinimumConfidence and "POSSESSION" or "TRACK"
		Runtime.IntentUntil = now + CONFIG.PreShotMemoryTime
		return false
	end
	local shooterLocal = goalToLocal(goal, root.Position)
	local projectionTime = (goal.homeDepth - shooterLocal.Z) / lookDepth
	if projectionTime <= 0 or projectionTime > CONFIG.AnticipationProjectionMaximumTime then return false end
	local maximumLateral = math.min(
		goal.halfWidth - CONFIG.PostInsidePadding,
		goal.halfWidth * CONFIG.PreShotMaximumLateralRatio
	)
	Runtime.IntentAimX = math.clamp(shooterLocal.X + look:Dot(goal.right) * projectionTime, -maximumLateral, maximumLateral)
	local lookTheta = tonumber(possessor:GetAttribute("LookTheta")) or 0
	lookTheta = math.clamp(lookTheta, CONFIG.ShootLookThetaMinimum, CONFIG.ShootLookThetaMaximum)
	local horizontalTravel = math.abs(shooterLocal.Z - goal.homeDepth)
	Runtime.IntentAimY = math.clamp(root.Position.Y + math.tan(lookTheta) * horizontalTravel, goal.bottomY, goal.topY)
	Runtime.IntentState = (kickAnimation or releaseSignal) and "RELEASE" or (confidence >= CONFIG.PreShotMinimumConfidence and "AIM READY" or "TRACK")
	Runtime.IntentUntil = now + CONFIG.PreShotMemoryTime
	return confidence >= CONFIG.PreShotMinimumConfidence
end

local function anticipationTarget(goal, ballPosition, possessor)
	local baseWorld = homeTarget(goal, ballPosition)
	local baseLocal = goalToLocal(goal, baseWorld)
	local preShotActive = updatePreShotIntent(goal, os.clock(), possessor)
	if preShotActive and Runtime.IntentAimX ~= nil then
		local weight = lerp(CONFIG.PreShotMinimumWeight, CONFIG.PreShotMaximumWeight, Runtime.IntentConfidence)
		local desiredX = lerp(baseLocal.X, Runtime.IntentAimX, weight)
		if Runtime.AnticipationX == nil or Runtime.AnticipationPlayer ~= possessor then
			Runtime.AnticipationX = baseLocal.X
		end
		Runtime.AnticipationX = lerp(Runtime.AnticipationX, desiredX, CONFIG.AnticipationSmoothingAlpha)
		Runtime.AnticipationPlayer = possessor
		Runtime.AnticipationShooterX = Runtime.IntentAimX
		Runtime.AnticipationWeight = weight
		Runtime.AnticipationActive = true
		return goalToWorld(goal, Runtime.AnticipationX, goal.homeDepth, goal.bottomY), true, "REPLICATED PRE-SHOT"
	end
	local maximumLateral = math.min(
		goal.halfWidth - CONFIG.PostInsidePadding,
		goal.halfWidth * CONFIG.AnticipationMaximumLateralRatio
	)
	local function returnBase()
		Runtime.AnticipationActive = false
		Runtime.AnticipationPlayer = nil
		Runtime.AnticipationShooterX = nil
		Runtime.AnticipationWeight = 0
		if Runtime.AnticipationX == nil then Runtime.AnticipationX = baseLocal.X
		else Runtime.AnticipationX = lerp(Runtime.AnticipationX, baseLocal.X, CONFIG.AnticipationSmoothingAlpha) end
		return goalToWorld(goal, math.clamp(Runtime.AnticipationX, -maximumLateral, maximumLateral), goal.homeDepth, goal.bottomY), false, "ANGLE"
	end
	if not Options.Anticipation
		or not possessor
		or Runtime.PossessorConfidence < CONFIG.AnticipationMinimumConfidence
		or Runtime.PossessorStablePlayer ~= possessor
		or os.clock() - Runtime.PossessorStableSince < CONFIG.AnticipationStablePossessionTime
		or Tracker.Velocity.Magnitude > CONFIG.AnticipationMaximumBallSpeed
		or math.max(0, -Tracker.Velocity:Dot(goal.field)) > CONFIG.AnticipationMaximumGoalwardSpeed then
		return returnBase()
	end
	local shooterRoot = getTrackedPlayerRoot(possessor)
	if not shooterRoot then return returnBase() end
	if (shooterRoot.Position - ballPosition).Magnitude > CONFIG.AnticipationMaximumBallDistance then return returnBase() end
	local shooterLocal = goalToLocal(goal, shooterRoot.Position)
	local look = safeUnit(horizontal(shooterRoot.CFrame.LookVector))
	local lookDepth = look:Dot(goal.field)
	local lookLateral = look:Dot(goal.right)
	-- goal.field zeigt vom Tor ins Feld. Ein Schütze blickt nur dann ungefähr
	-- aufs verteidigte Tor, wenn seine lokale Tiefenrichtung negativ ist.
	if lookDepth >= -CONFIG.ShooterFacingMinimum then return returnBase() end
	local projectionTime = (goal.homeDepth - shooterLocal.Z) / lookDepth
	if projectionTime <= 0 or projectionTime > CONFIG.AnticipationProjectionMaximumTime then return returnBase() end
	local shooterTargetX = shooterLocal.X + lookLateral * projectionTime
	shooterTargetX = math.clamp(shooterTargetX, -maximumLateral, maximumLateral)
	local facingConfidence = clamp01((-lookDepth - CONFIG.ShooterFacingMinimum) / math.max(1 - CONFIG.ShooterFacingMinimum, 0.01))
	local weight = lerp(CONFIG.ShooterAimMinimumWeight, CONFIG.ShooterAimMaximumWeight, Runtime.PossessorConfidence * facingConfidence)
	local desiredX = lerp(baseLocal.X, shooterTargetX, weight)
	desiredX = math.clamp(desiredX, -maximumLateral, maximumLateral)
	if Runtime.AnticipationX == nil or Runtime.AnticipationPlayer ~= possessor then Runtime.AnticipationX = baseLocal.X end
	Runtime.AnticipationX = lerp(Runtime.AnticipationX, desiredX, CONFIG.AnticipationSmoothingAlpha)
	Runtime.AnticipationPlayer = possessor
	Runtime.AnticipationShooterX = shooterTargetX
	Runtime.AnticipationWeight = weight
	Runtime.AnticipationActive = true
	return goalToWorld(goal, Runtime.AnticipationX, goal.homeDepth, goal.bottomY), true, "V16 SHOOTER ANTICIPATION"
end

local function confirmDiveCandidate(side, immediate, ballETA)
	if Runtime.DiveCandidateShotId ~= Runtime.TrajectoryId then
		Runtime.DiveCandidateShotId = Runtime.TrajectoryId
		Runtime.DiveCandidateSide = side
		Runtime.DiveCandidateFrames = 1
	elseif Runtime.DiveCandidateSide == side then
		Runtime.DiveCandidateFrames += 1
	else
		Runtime.DiveCandidateSide = side
		Runtime.DiveCandidateFrames = 1
	end
	local emergencyOverride = ballETA and ballETA <= CONFIG.PredictionEmergencyOverrideTime
	local trustedImmediate = immediate and (Runtime.PredictionConfidence >= CONFIG.PredictionDiveConfidence or emergencyOverride)
	local requiredFrames = CONFIG.NormalDiveConfirmFrames
	if Runtime.PredictionConfidence < CONFIG.PredictionDiveConfidence and not emergencyOverride then
		requiredFrames += CONFIG.UncertainDiveExtraFrames
	end
	return trustedImmediate or Runtime.DiveCandidateFrames >= requiredFrames
end

local function resetDiveCandidate()
	Runtime.DiveCandidateShotId = Runtime.TrajectoryId
	Runtime.DiveCandidateSide = 0
	Runtime.DiveCandidateFrames = 0
end

local function calculatePhysicalDiveLead(residualDistance, diveReach, extraBuffer, profile)
	local fraction = clamp01(residualDistance / math.max(diveReach, 0.01))
	local learnedContact = profile and profile.contact or Runtime.DiveContactTime
	local windup = profile and profile.windup or math.clamp(learnedContact * 0.26, 0.055, 0.13)
	local t25 = profile and profile.t25 or learnedContact * 0.23
	local t50 = profile and profile.t50 or learnedContact * 0.45
	local t75 = profile and profile.t75 or learnedContact * 0.69
	local t100 = profile and profile.t100 or math.max(0.055, learnedContact - windup)
	local travelTime
	if fraction <= 0.25 then
		travelTime = lerp(0.02, t25, fraction / 0.25)
	elseif fraction <= 0.50 then
		travelTime = lerp(t25, t50, (fraction - 0.25) / 0.25)
	elseif fraction <= 0.75 then
		travelTime = lerp(t50, t75, (fraction - 0.50) / 0.25)
	else
		travelTime = lerp(t75, t100, (fraction - 0.75) / 0.25)
	end
	-- Die Ballmessung wurde bereits teilweise um den Ping extrapoliert. Hier
	-- wird deshalb nur der noch nicht kompensierte Rest als Serverpuffer addiert.
	local residualPing = Tracker.NetworkPing
		* math.max(0, 1 - CONFIG.NetworkPingWeight)
		* CONFIG.DiveResidualPingWeight
	return CONFIG.ReactionLatency + CONFIG.DiveInputLatency + windup + travelTime
		+ CONFIG.DiveServerMargin + residualPing + (extraBuffer or CONFIG.DiveContactBuffer)
end

local function calculateHitboxDiveLead(goal, interceptPosition, keeperPosition, projectedKeeperX, side, extraBuffer, profile)
	if not goal or not interceptPosition or not keeperPosition or not profile
		or (profile.hitboxDives or 0) <= 0 or not profile.hitboxTimeline then
		return nil
	end
	if (profile.hitboxBinCount or 0) < CONFIG.DiveHitboxMinimumBins then return nil end

	local keeperLocal = goalToLocal(goal, keeperPosition)
	local projectedStart = keeperPosition + goal.right * (projectedKeeperX - keeperLocal.X)
	local ballRadius = getTrackedBallRadius() + CONFIG.DiveHitboxContactPadding
	local bestElapsed = nil
	local maximumBin = math.ceil(CONFIG.DiveMaximumActiveTime / CONFIG.DiveHitboxSampleStep)
	for bin = 0, maximumBin do
		local sample = profile.hitboxTimeline[bin]
		if sample and sample.time >= CONFIG.DiveHitboxMinimumContactTime then
			local center = projectedStart
				+ goal.right * (sample.lateral * side)
				+ Vector3.yAxis * sample.vertical
				+ goal.field * sample.depth
			local offset = interceptPosition - center
			local insideLateral = math.abs(offset:Dot(goal.right)) <= sample.extentLateral + ballRadius
			local insideVertical = math.abs(offset.Y) <= sample.extentVertical + ballRadius
			local insideDepth = math.abs(offset:Dot(goal.field)) <= sample.extentDepth + ballRadius
			if insideLateral and insideVertical and insideDepth then
				bestElapsed = sample.time
				break
			end
		end
	end
	if not bestElapsed then return nil end

	local residualPing = Tracker.NetworkPing
		* math.max(0, 1 - CONFIG.NetworkPingWeight)
		* CONFIG.DiveResidualPingWeight
	return CONFIG.ReactionLatency + CONFIG.DiveInputLatency + bestElapsed
		+ CONFIG.DiveServerMargin + residualPing
		+ (extraBuffer or CONFIG.DiveContactBuffer) + CONFIG.DiveHitboxLeadSafety
end

local function calculateAdaptiveDiveLead(goal, interceptPosition, keeperPosition, projectedKeeperX, side, residualDistance, diveReach, extraBuffer, profile)
	local hitboxLead = calculateHitboxDiveLead(
		goal,
		interceptPosition,
		keeperPosition,
		projectedKeeperX,
		side,
		extraBuffer,
		profile
	)
	if hitboxLead then
		Runtime.DiveTimingModel = "HITBOX"
		return hitboxLead
	end
	Runtime.DiveTimingModel = "MOTION"
	return calculatePhysicalDiveLead(residualDistance, diveReach, extraBuffer, profile)
end

local function updateVirtualGateTelemetry(goal, now)
	if not Tracker.Position then return 0, 0 end
	local currentDepth = goalToLocal(goal, Tracker.Position).Z
	if Runtime.VirtualGateShotId ~= Runtime.TrajectoryId or Runtime.VirtualGateGoal ~= goal then
		Runtime.VirtualGateShotId = Runtime.TrajectoryId
		Runtime.VirtualGateGoal = goal
		Runtime.VirtualGateLastDepth = currentDepth
		Runtime.VirtualGateLastTime = now
		-- Der erkannte Schussbeginn ist die erste mathematische Messmarke.
		-- Dadurch liefert auch ein sehr nah gestarteter Schuss bereits beim
		-- nächsten Gate eine brauchbare Segmentgeschwindigkeit.
		Runtime.VirtualGateLastCrossDepth = currentDepth
		Runtime.VirtualGateLastCrossTime = now
		Runtime.VirtualGateCrossCount = 1
		Runtime.VirtualGateSpeed = 0
		Runtime.VirtualGateConfidence = 0
		return 0, 0
	end
	local previousDepth = Runtime.VirtualGateLastDepth
	local previousTime = Runtime.VirtualGateLastTime
	if previousDepth and previousTime and now > previousTime and currentDepth < previousDepth - 0.001 then
		local nearSpan = math.max(0, goal.maximumDepth - goal.homeDepth)
		local gates = {
			goal.halfWidth * CONFIG.FarShotOriginRatio,
			goal.dangerDepth,
			goal.maximumDepth,
			goal.homeDepth + nearSpan * (2 / 3),
			goal.homeDepth + nearSpan * (1 / 3),
			goal.homeDepth,
		}
		table.sort(gates, function(a, b) return a > b end)
		for _, gateDepth in ipairs(gates) do
			if previousDepth > gateDepth and currentDepth <= gateDepth then
				local alpha = math.clamp((previousDepth - gateDepth) / math.max(previousDepth - currentDepth, 0.0001), 0, 1)
				local crossingTime = lerp(previousTime, now, alpha)
				if Runtime.VirtualGateLastCrossDepth and Runtime.VirtualGateLastCrossTime then
					local depthTravel = Runtime.VirtualGateLastCrossDepth - gateDepth
					local elapsed = crossingTime - Runtime.VirtualGateLastCrossTime
					if depthTravel > 0.05 and elapsed > 0.001 then
						local measuredSpeed = depthTravel / elapsed
						if measuredSpeed >= CONFIG.VirtualGateMinimumSpeed and measuredSpeed <= CONFIG.VirtualGateMaximumSpeed then
							Runtime.VirtualGateSpeed = Runtime.VirtualGateSpeed > 0
								and lerp(Runtime.VirtualGateSpeed, measuredSpeed, 0.58)
								or measuredSpeed
							Runtime.VirtualGateCrossCount += 1
							Runtime.VirtualGateConfidence = clamp01((Runtime.VirtualGateCrossCount - 1) / 2)
							Runtime.VirtualGateLastEvent = now
							Runtime.Event = string.format("VIRTUAL GATE %.1f", Runtime.VirtualGateSpeed)
						end
					end
				else
					Runtime.VirtualGateCrossCount = 1
				end
				Runtime.VirtualGateLastCrossDepth = gateDepth
				Runtime.VirtualGateLastCrossTime = crossingTime
			end
		end
	end
	Runtime.VirtualGateLastDepth = currentDepth
	Runtime.VirtualGateLastTime = now
	if now - Runtime.VirtualGateLastEvent > CONFIG.VirtualGateMaximumAge then
		Runtime.VirtualGateConfidence = 0
	end
	return Runtime.VirtualGateSpeed, Runtime.VirtualGateConfidence
end

local function gateCorrectedETA(goal, targetDepth, predictedTime)
	if Runtime.VirtualGateSpeed <= CONFIG.VirtualGateMinimumSpeed or Runtime.VirtualGateConfidence <= 0 then return predictedTime end
	local currentDepth = goalToLocal(goal, Tracker.Position).Z
	local measuredTime = math.max(0, (currentDepth - targetDepth) / Runtime.VirtualGateSpeed)
	if measuredTime > CONFIG.MaximumPredictionTime then return predictedTime end
	local baseBlend = Tracker.Grounded and CONFIG.VirtualGateGroundBlend or CONFIG.VirtualGateBlend
	local weight = baseBlend * Runtime.VirtualGateConfidence
	return lerp(predictedTime, measuredTime, weight)
end

local function updateController(now, keeper, ball)
	Runtime.RunETA = math.huge
	Runtime.DiveETA = math.huge
	Runtime.BallETA = math.huge
	Runtime.RunMargin = -math.huge
	Runtime.DiveMargin = -math.huge
	Runtime.SaveMethod = "WAIT"
	-- Grab bleibt unabhängig von Goal-/Movement-Kalibrierung aktiv.
	Runtime.NativeGrab, Runtime.GrabSignal = isNativeGrabbable(keeper)
	Runtime.HoldingBall = confirmedHoldingBall(keeper)
	local preparedETA, preparedPosition, preparedDistance = predictGrabPreparation(keeper)
	Runtime.PreparedGrabETA = preparedETA or math.huge
	Runtime.PreparedGrabUntil = preparedETA and (now + preparedETA) or 0
	if Runtime.HoldingBall then
		learnDiveContact(now, "HOLD")
		if Runtime.Diving then finalizeDiveHitboxCalibration() end
		Runtime.State, Runtime.Action, Runtime.GrabFSM = "HOLDING", "HOLD", "CONFIRMED"
		if Runtime.LoggedOutcomeShotId ~= Runtime.ShotId then
			Runtime.LoggedOutcomeShotId = Runtime.ShotId
			Runtime.Event = "HOLDING SAVE"
		end
		Runtime.SaveMethod = "HOLDING"
		Runtime.Diving = false
		if Runtime.ForcedMoveOwner == "DIVE" then Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil end
		Runtime.RecoveryRequired = false
		Runtime.RecoveryReason = "NONE"
		Runtime.DiveContactDetected = true
		Runtime.DiveContactKind = "HOLD"
		Runtime.ContactWindowUntil = 0
		Runtime.GetUpEarliest = 0
		Runtime.GetUpDeadline = 0
		resetDiveCandidate()
		setSavePhase("HOLDING")
		Runtime.ShotOriginPosition = nil
		clearWorldTarget()
		return nil, nil
	end
	if Runtime.SavePhase == "HOLDING" then setSavePhase("READY", "BALL RELEASED") end
	if Runtime.GrabFSM == "CONFIRMED" then Runtime.GrabFSM = "ARMED" end
	if Runtime.GrabFSM == "DIVE LOCK" and not Runtime.Diving and Runtime.SavePhase ~= "DIVE_ACTIVE" then Runtime.GrabFSM = "ARMED" end
	if preparedETA and not Runtime.NativeGrab and Runtime.GrabFSM == "ARMED" then Runtime.GrabFSM = "PREPARED" end
	if not preparedETA and Runtime.GrabFSM == "PREPARED" then Runtime.GrabFSM = "ARMED" end
	if Runtime.NativeGrab then pressGrab(keeper) end

	local goal = getDefendedGoal(keeper)
	Runtime.DefendedGoal = goal
	Runtime.CalibrationOK = goal ~= nil and goal.field ~= nil
	if not Runtime.CalibrationOK then
		Runtime.State, Runtime.Action = "CALIBRATION FAILED", "STOP"
		setSavePhase("FAULT", "GOAL CALIBRATION FAILED")
		clearWorldTarget()
		return nil, nil
	end
	if not validateReferenceFrame(goal, keeper, now) then
		Runtime.State, Runtime.Action, Runtime.SaveMethod = "REFERENCE FAULT", "STOP", "FAULT"
		setSavePhase("FAULT", Runtime.PositionFault)
		clearWorldTarget()
		return nil, nil
	end
	if Runtime.SavePhase == "CALIBRATING" then setSavePhase("READY", "CALIBRATION READY") end
	-- Die Save-Lifecycle-Phasen besitzen exklusive Bewegungspriorität. Solange
	-- der native Dive läuft oder der Avatar aufsteht, darf kein neuer Laufvektor
	-- die Physik überschreiben. Grab bleibt oben trotzdem weiter aktiv.
	if Runtime.Diving or Runtime.SavePhase == "DIVE_ACTIVE" then
		Runtime.State, Runtime.Action, Runtime.SaveMethod = "DIVE ACTIVE", Runtime.DiveDirectionName, "DIVE"
		clearWorldTarget()
		return nil, nil
	end
	if Runtime.SavePhase == "CONTACT_WINDOW" then
		Runtime.State, Runtime.Action, Runtime.SaveMethod = "CONTACT WINDOW", "WATCH BALL", "POST_DIVE"
		clearWorldTarget()
		return nil, nil
	end
	if Runtime.SavePhase == "GETTING_UP" then
		Runtime.State, Runtime.Action, Runtime.SaveMethod = "GETTING UP", "WAIT FOR CONTROL", "RECOVERY"
		clearWorldTarget()
		return nil, nil
	end

	local keeperLocal = goalToLocal(goal, keeper)
	local ballLocal = goalToLocal(goal, Tracker.Position)
	local predictionConfidence = updatePredictionConfidence(now)
	local gateSpeed, gateConfidence = updateVirtualGateTelemetry(goal, now)
	local possessor = updateLikelyPossessor(now)
	Runtime.AnticipationActive = false
	if not Runtime.ShotOriginPosition then Runtime.ShotOriginPosition = Tracker.Position end
	local shotOriginLocal = goalToLocal(goal, Runtime.ShotOriginPosition)
	local shotOriginRatio = math.max(0, shotOriginLocal.Z) / math.max(goal.halfWidth, 0.01)
	local closeOriginShot = shotOriginRatio <= CONFIG.CloseShotOriginRatio
	local farOriginShot = shotOriginRatio >= CONFIG.FarShotOriginRatio
	Runtime.ShotDistanceClass = closeOriginShot and "CLOSE" or (farOriginShot and "FAR" or "MID")
	-- Torgefahr wird an der echten Torlinie geprüft. Der Save-Punkt liegt
	-- bevorzugt auf der sicheren Keeper-Tiefe; ist der Ball schon dahinter,
	-- wird der verbleibende Goal-Line-Impact verwendet.
	local goalImpact = findPlaneIntercept(goal, CONFIG.GoalLineMinimumDepth)
	local saveIntercept = findPlaneIntercept(goal, goal.homeDepth)
	-- Die virtuellen Ebenen korrigieren nur die ETA. X/Y bleiben vollständig
	-- beim adaptiven Physikmodell, damit Curve und Höhe nicht verfälscht werden.
	if goalImpact then
		goalImpact.time = gateCorrectedETA(goal, CONFIG.GoalLineMinimumDepth, goalImpact.time)
		Runtime.PredictionCorridorMinX = goalImpact.corridorMinX
		Runtime.PredictionCorridorMaxX = goalImpact.corridorMaxX
		Runtime.PredictionCorridorMinY = goalImpact.corridorMinY
		Runtime.PredictionCorridorMaxY = goalImpact.corridorMaxY
		if not Runtime.PredictedGoalImpact then
			Runtime.PredictedGoalImpact = {
				position = goalImpact.position,
				localPosition = goalImpact.localPosition,
				confidence = predictionConfidence,
			}
		end
	end
	if saveIntercept then
		saveIntercept.time = gateCorrectedETA(goal, goal.homeDepth, saveIntercept.time)
	end
	local onTarget = isOnTarget(goal, goalImpact)
	local intercept = saveIntercept or goalImpact
	if Runtime.ShotId > 0 and Runtime.LoggedOutcomeShotId ~= Runtime.ShotId
		and ballLocal.Z <= CONFIG.GoalLineMinimumDepth - 0.25 then
		Runtime.LoggedOutcomeShotId = Runtime.ShotId
		local insideFrame = math.abs(ballLocal.X) <= goal.halfWidth + CONFIG.BallRadius
			and Tracker.Position.Y >= goal.bottomY - CONFIG.BallRadius
			and Tracker.Position.Y <= goal.topY + CONFIG.BallRadius
		local prediction = Runtime.PredictedGoalImpact
		if prediction and prediction.localPosition
			and (prediction.confidence or 0) >= CONFIG.OutcomeBiasMinimumConfidence then
			local lateralError = math.clamp(ballLocal.X - prediction.localPosition.X, -2.5, 2.5)
			local verticalError = math.clamp(Tracker.Position.Y - prediction.position.Y, -2.0, 2.0)
			local correction = goal.right * lateralError + Vector3.yAxis * verticalError
			local learnAlpha = Runtime.OutcomeBiasSamples < 3
				and CONFIG.OutcomeBiasInitialAlpha or CONFIG.OutcomeBiasStableAlpha
			Runtime.PredictionBias += correction * learnAlpha
			if Runtime.PredictionBias.Magnitude > CONFIG.OutcomeBiasMaximum then
				Runtime.PredictionBias = Runtime.PredictionBias.Unit * CONFIG.OutcomeBiasMaximum
			end
			Runtime.OutcomeBiasSamples += 1
		end
		Runtime.Event = insideFrame and "GOAL LINE CROSSED" or "MISS / OUTSIDE FRAME"
	end
	local rawGoalwardSpeed = math.max(0, -Tracker.Velocity:Dot(goal.field))
	local goalwardSpeed = rawGoalwardSpeed
	if gateConfidence > 0 and gateSpeed > 0 then
		local baseGateBlend = Tracker.Grounded and CONFIG.VirtualGateGroundBlend or CONFIG.VirtualGateBlend
		goalwardSpeed = lerp(rawGoalwardSpeed, gateSpeed, baseGateBlend * gateConfidence)
	end
	local immediateThreat = onTarget and goalImpact
		and goalImpact.time <= CONFIG.ThreatLooseBallLockTime
		and goalwardSpeed >= CONFIG.ThreatMinimumGoalwardSpeed
	local eta = intercept and intercept.time or math.huge
	local fastShot = goalwardSpeed >= CONFIG.FastShotImmediateSpeed
	local extremeSpeed = goalwardSpeed >= CONFIG.ExtremeShotSpeed
	local slowShot = goalwardSpeed > 0 and goalwardSpeed <= CONFIG.SlowShotSpeed
	local mediumShot = goalwardSpeed > CONFIG.SlowShotSpeed and goalwardSpeed < CONFIG.FastShotImmediateSpeed
	local groundMoveShot = Tracker.Grounded and not fastShot and goalwardSpeed > 0 and goalwardSpeed <= CONFIG.GroundMoveGrabMaxSpeed
	local slowCommitTime = groundMoveShot and CONFIG.GroundShotDiveCommitTime or CONFIG.SlowShotDiveCommitTime
	local timeConfidence = 1 - clamp01(eta / math.max(CONFIG.ThreatLooseBallLockTime, 0.01))
	local speedConfidence = clamp01(goalwardSpeed / CONFIG.FastShotImmediateSpeed)
	Runtime.ShotConfidence = onTarget and clamp01(0.42 + speedConfidence * 0.33 + timeConfidence * 0.25) or 0
	Runtime.ShotUrgency = not onTarget and "NONE"
		or (eta <= CONFIG.ExtremeEmergencyTime and "EXTREME")
		or (eta <= CONFIG.EmergencyDiveTime and "EMERGENCY")
		or ((slowShot or groundMoveShot) and eta > slowCommitTime and "SLOW")
		or (mediumShot and "CONTROLLED")
		or ((fastShot or eta <= CONFIG.FastShotImmediateTime) and "FAST")
		or "NORMAL"
	local danger = ballLocal.Z >= -1.5 and ballLocal.Z <= goal.dangerDepth and math.abs(ballLocal.X) <= goal.halfWidth + 4
	local ballInsideEnvelope = pointInsideKeeperEnvelope(goal, Tracker.Position, CONFIG.BallChaseBoundaryTolerance)
	local loose = danger and ballLocal.Z <= goal.maximumDepth + CONFIG.ApproachBehindBall
		and horizontal(Tracker.Position - keeper).Magnitude <= CONFIG.LooseBallMaximumDistance
		and Tracker.Velocity.Magnitude <= CONFIG.LooseBallMaximumSpeed and possessor == nil
		and ballInsideEnvelope
		and not onTarget

	-- Nach jedem Dive wird erst die sichere Torposition wiederhergestellt. Eine
	-- echte, akute Abpraller-Bahn darf diesen Rückweg unterbrechen; dadurch kann
	-- ein zweiter Save auf der neuen TrajectoryId erfolgen, ohne dass der Keeper
	-- bei einem harmlosen Ball außerhalb des Tores stehen bleibt.
	if Runtime.RecoveryRequired then
		local urgentRebound = onTarget and goalImpact
			and goalImpact.time <= CONFIG.RecoveryThreatMaximumTime
			and goalwardSpeed >= CONFIG.ThreatMinimumGoalwardSpeed
		if urgentRebound then
			setSavePhase("REBOUND_DEFENSE")
			Runtime.State, Runtime.Action = "REBOUND", "DEFEND NEW TRAJECTORY"
		else
			local recoveryTarget, outsideSafeZone = postDiveRecoveryTarget(goal, keeper)
			local recoveryDistance = horizontal(recoveryTarget - keeper).Magnitude
			local keeperSpeed = horizontal(Runtime.LastKeeperVelocity).Magnitude
			Runtime.SaveMethod = "RECOVERY"
			Runtime.State = outsideSafeZone and "RECOVER TO ZONE" or "RECOVER HOME"
			Runtime.Action = Runtime.RecoveryReason
			setSavePhase(outsideSafeZone and "RECOVER_TO_ZONE" or "RECOVER_TO_HOME")
			if not outsideSafeZone and recoveryDistance <= CONFIG.RecoveryArrivalDistance and keeperSpeed <= CONFIG.RecoveryHomeSpeed then
				Runtime.RecoveryRequired = false
				Runtime.RecoveryReason = "NONE"
				Runtime.DiveContactDetected = false
				Runtime.DivePreviousBallVelocity = nil
				setSavePhase("READY", "RECOVERY COMPLETE")
			else
				setWorldTarget(goal, recoveryTarget, "MANDATORY POST-DIVE RETURN", false)
				return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal, recoveryDistance = recoveryDistance}
			end
		end
	end
	if Runtime.SavePhase ~= "REBOUND_DEFENSE" then
		setSavePhase(onTarget and "SHOT_TRACKING" or "POSITIONING")
	end

	-- Safety-Recovery hat immer höchste Bewegungspriorität.
	if keeperLocal.Z < CONFIG.GoalLineMinimumDepth - 0.25 or keeperLocal.Z > goal.maximumDepth + 0.35 or math.abs(keeperLocal.X) > goal.halfWidth + CONFIG.SaveOutsidePadding + 0.5 then
		Runtime.RecoveryRequired = true
		Runtime.RecoveryReason = "SAFETY BOUNDARY"
		setSavePhase("RECOVER_TO_ZONE")
		Runtime.SaveMethod = "RECOVERY"
		Runtime.State, Runtime.Action = "RECOVERY", "RETURN HOME"
		setWorldTarget(goal, goalToWorld(goal, 0, goal.homeDepth, goal.bottomY), "SAFETY", false)
		return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal}
	end

	-- Sobald das echte Spiel den Ball als fangbar markiert, wird kein neuer
	-- Dive committed. Der Keeper bewegt sich weiter auf die Torseite des Balls,
	-- während der permanente Grab-Manager parallel pulst.
	local catchDistance = (Tracker.Position - keeper).Magnitude
	local urgentCatchBypass = immediateThreat and goalImpact
		and goalImpact.time <= CONFIG.EmergencyDiveTime
		and math.abs(goalImpact.localPosition.X - keeperLocal.X) > CONFIG.EmergencyCenterRange
	if Runtime.NativeGrab and catchDistance <= CONFIG.GrabSanityDistance and not urgentCatchBypass then
		resetDiveCandidate()
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "GRAB"
		Runtime.State, Runtime.Action = "CATCH WINDOW", "GRAB + MOVE"
		-- Nie mehr vom fangbaren Ball zurückweichen: Ziel bleibt auf der
		-- Torseite des Balls und wird lediglich an der sicheren Tiefe begrenzt.
		local catchTarget = looseBallTarget(goal, Tracker.Position, true, keeper)
		setWorldTarget(goal, catchTarget, "NATIVE CATCH", true)
		return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal}
	end
	if preparedETA and preparedPosition and preparedDistance <= CONFIG.GrabPhysicalFallbackDistance + 0.9
		and danger and possessor == nil and not urgentCatchBypass
		and pointInsideKeeperEnvelope(goal, preparedPosition, CONFIG.BallChaseBoundaryTolerance)
		and (not onTarget or Tracker.Velocity.Magnitude <= CONFIG.GroundMoveGrabMaxSpeed) then
		resetDiveCandidate()
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "PREPARE_GRAB"
		Runtime.State, Runtime.Action = "CATCH APPROACH", "POSITION FOR NATIVE GRAB"
		setWorldTarget(goal, looseBallTarget(goal, preparedPosition, true, keeper), "PREDICTED CONTACT", true)
		return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal, preparedETA = preparedETA}
	end

	-- Ein sehr langsamer Bodenball, der bereits sicher innerhalb der begrenzten
	-- Keeper-Zone liegt, wird kontrolliert von der Torseite eingesammelt. Nur
	-- genügend Restzeit und kein erkannter Gegnerbesitz erlauben dieses Vorrücken.
	local safeSlowCollection = onTarget and Tracker.Grounded and (slowShot or groundMoveShot)
		and goalImpact and goalImpact.time >= CONFIG.SlowCollectionMinimumTime
		and ballLocal.Z <= goal.maximumDepth
		and ballInsideEnvelope
		and catchDistance <= CONFIG.SlowCollectionMaximumDistance
		and possessor == nil
	if safeSlowCollection then
		resetDiveCandidate()
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "RUN_GRAB"
		Runtime.State, Runtime.Action = "SLOW SHOT", "SAFE COLLECT + GRAB"
		setWorldTarget(goal, looseBallTarget(goal, Tracker.Position, true, keeper), "SLOW SAFE COLLECT", true)
		return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal, urgency = "SLOW"}
	end

	if loose then
		resetDiveCandidate()
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "RUN_GRAB"
		Runtime.State, Runtime.Action = "COLLECT", "RUN + GRAB"
		setWorldTarget(goal, looseBallTarget(goal, Tracker.Position, true, keeper), "GOAL-SIDE COLLECT", true)
		return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal}
	end

	if not onTarget then
		Runtime.StableInterceptX = nil
		Runtime.StableInterceptY = nil
		Runtime.StableInterceptTime = nil
		resetDiveCandidate()
		setSavePhase("TRACKING")
		Runtime.SaveMethod = "POSITION"
		local positioningTarget, anticipating, anticipationReason = anticipationTarget(goal, Tracker.Position, possessor)
		Runtime.State = anticipating and "ANTICIPATE" or "POSITION"
		Runtime.Action = Runtime.IntentState == "AIM READY" and "PRE-SHOT ANGLE"
			or (anticipating and "BALL + SHOOTER ANGLE" or "ANGLE COVER")
		setWorldTarget(goal, positioningTarget, anticipationReason or "ANGLE", false)
		return intercept, {keeperLocal = keeperLocal, ballLocal = ballLocal}
	end

	Runtime.State = "SHOT"
	local interceptLocal = intercept.localPosition
	local rawInterceptX = interceptLocal.X
	local rawInterceptY = intercept.position.Y
	local rawInterceptTime = intercept.time
	if Runtime.StableInterceptShotId ~= Runtime.TrajectoryId or Runtime.StableInterceptX == nil then
		Runtime.StableInterceptShotId = Runtime.TrajectoryId
		Runtime.StableInterceptX = rawInterceptX
		Runtime.StableInterceptY = rawInterceptY
		Runtime.StableInterceptTime = rawInterceptTime
	else
		local aimAlpha = fastShot and CONFIG.FastAimAlpha
			or (mediumShot and CONFIG.MediumAimAlpha)
			or ((slowShot or groundMoveShot) and CONFIG.SlowAimAlpha or CONFIG.NormalAimAlpha)
		-- Bei unsicherer Bahn wird der alte Fangpunkt nicht hektisch verworfen.
		-- Akute Nahschüsse behalten trotzdem ihre schnelle Reaktion.
		if not closeOriginShot and eta > CONFIG.PredictionEmergencyOverrideTime then
			aimAlpha *= lerp(0.48, 1, predictionConfidence)
		end
		if farOriginShot and eta > CONFIG.FastShotImmediateTime then aimAlpha = math.min(aimAlpha, CONFIG.MediumAimAlpha) end
		if closeOriginShot then aimAlpha = math.max(aimAlpha, 0.82) end
		-- Wenn der rohe Trefferpunkt direkt am Keeper liegt, schnell zur Mitte
		-- zurückkehren. Dadurch erzeugt altes Seitentracking keinen falschen Dive.
		if math.abs(rawInterceptX - keeperLocal.X) <= CONFIG.CenterBlockRange then aimAlpha = math.max(aimAlpha, 0.78) end
		local urgencyAlpha = 1 - clamp01(rawInterceptTime / math.max(CONFIG.FastShotImmediateTime, 0.01))
		aimAlpha = math.max(aimAlpha, lerp(0.42, 0.94, urgencyAlpha))
		if Tracker.CurveConfirmed then aimAlpha = math.max(aimAlpha, 0.62) end
		aimAlpha *= lerp(0.72, 1, predictionConfidence)
		Runtime.StableInterceptX = lerp(Runtime.StableInterceptX, rawInterceptX, aimAlpha)
		Runtime.StableInterceptY = lerp(Runtime.StableInterceptY or rawInterceptY, rawInterceptY, math.min(1, aimAlpha + 0.08))
		Runtime.StableInterceptTime = lerp(Runtime.StableInterceptTime or rawInterceptTime, rawInterceptTime, math.min(1, aimAlpha + 0.14))
	end
	local stableInterceptX = Runtime.StableInterceptX
	local likelyInterceptTime = math.max(0, Runtime.StableInterceptTime or intercept.time)
	local timingSpread = (intercept.uncertainty or 0) / math.max(goalwardSpeed, CONFIG.MinimumGoalwardSpeed)
	intercept.likelyTime = likelyInterceptTime
	intercept.earliestTime = math.max(0, likelyInterceptTime - timingSpread)
	intercept.latestTime = math.min(CONFIG.MaximumPredictionTime, likelyInterceptTime + timingSpread)
	-- Bei einer unsicheren Messung wird der Startzeitpunkt vorsichtig zwischen
	-- frühestem und wahrscheinlichstem Kontakt gewählt. Hohe Konfidenz nutzt
	-- fast vollständig die wahrscheinlichste ETA.
	intercept.time = lerp(intercept.earliestTime, likelyInterceptTime, predictionConfidence)
	intercept.position = goalToWorld(goal, stableInterceptX, intercept.localPosition.Z, Runtime.StableInterceptY or intercept.position.Y)
	intercept.localPosition = goalToLocal(goal, intercept.position)
	-- Der Keeper bewegt sich während der Netzwerk-/Entscheidungszeit weiter.
	-- Die Dive-Distanz wird deshalb von seiner kurz vorausgesagten Position aus
	-- gemessen. Bei geringer Modellkonfidenz nutzt die Entscheidung den nächsten
	-- Rand des Trefferkorridors und wartet auf stabilere Messungen.
	local keeperProjectionTime = math.min(intercept.time, CONFIG.KeeperProjectionMaximumTime)
	local keeperLateralVelocity = Runtime.LastKeeperVelocity:Dot(goal.right)
	local projectedKeeperX = keeperLocal.X + keeperLateralVelocity * keeperProjectionTime * 0.72
	local projectionLimit = Runtime.RunSpeed * keeperProjectionTime
	projectedKeeperX = math.clamp(projectedKeeperX, keeperLocal.X - projectionLimit, keeperLocal.X + projectionLimit)
	local centralLateralDistance = math.abs(stableInterceptX - projectedKeeperX)
	local corridorMinX = intercept.corridorMinX or Runtime.PredictionCorridorMinX or stableInterceptX
	local corridorMaxX = intercept.corridorMaxX or Runtime.PredictionCorridorMaxX or stableInterceptX
	if corridorMinX > corridorMaxX then corridorMinX, corridorMaxX = corridorMaxX, corridorMinX end
	local corridorLateralDistance = projectedKeeperX < corridorMinX and corridorMinX - projectedKeeperX
		or (projectedKeeperX > corridorMaxX and projectedKeeperX - corridorMaxX or 0)
	local emergencyPrediction = intercept.time <= CONFIG.PredictionEmergencyOverrideTime
	local lateralDistance = (predictionConfidence >= CONFIG.PredictionDiveConfidence or emergencyPrediction)
		and centralLateralDistance or corridorLateralDistance
	local catchRadius, relativeHeight = catchRadiusAtHeight(goal, intercept.position.Y)
	local target = goalToWorld(goal, stableInterceptX, goal.homeDepth, goal.bottomY)
	local runDirection = safeUnit(horizontal(target - keeper))
	local depthDelta = goal.homeDepth - keeperLocal.Z
	local pureRunReach = reachableRunDistance(intercept.time, runDirection)
	local runReach = pureRunReach + catchRadius - CONFIG.RunSafetyMargin
	local side = sign(stableInterceptX - projectedKeeperX)
	if side == 0 then side = sign(stableInterceptX) end
	if side == 0 then side = 1 end
	local diveTier = selectDiveTier(goal, intercept.position.Y, intercept.uncertainty, side)
	local diveProfile = getDiveProfile(side, diveTier)
	local fallbackDiveReach = side < 0 and Runtime.DiveReachLeft or Runtime.DiveReachRight
	local diveReach = diveProfile and diveProfile.reach or fallbackDiveReach
	local tierCenterRatio = diveTier == "HIGH" and 0.82 or (diveTier == "LOW" and 0.18 or 0.50)
	local tierCenterY = goal.bottomY + (goal.topY - goal.bottomY) * tierCenterRatio
	local verticalError = math.abs(intercept.position.Y - tierCenterY)
	local verticalFeasible = verticalError <= getDiveVerticalTolerance(diveTier) + (intercept.uncertainty or 0) * 0.35
	local normalCatchSoon = preparedETA and preparedDistance
		and preparedDistance <= CONFIG.PredictedCatchRadius + 0.9
		and preparedETA <= CONFIG.GrabPrepareMaximumTime
	local runDistanceNeeded = math.max(0, lateralDistance - catchRadius + CONFIG.RunSafetyMargin)
	local runETA = timeToRunDistance(runDistanceNeeded, runDirection, depthDelta)
	local currentDiveResidual = math.max(0, lateralDistance - catchRadius)
	local diveETA = calculateAdaptiveDiveLead(
		goal,
		intercept.position,
		keeper,
		projectedKeeperX,
		side,
		currentDiveResidual,
		diveReach,
		CONFIG.DiveContactBuffer,
		diveProfile
	)
	local runCanCatch = runETA <= intercept.time + CONFIG.RunArrivalTolerance
	local conservativeDiveReach = math.max(CONFIG.MinimumDiveReach, diveReach - (intercept.uncertainty or 0) * 0.25)
	local diveFeasible = currentDiveResidual <= conservativeDiveReach and verticalFeasible
	local predictionTrusted = predictionConfidence >= CONFIG.PredictionDiveConfidence
		or emergencyPrediction or closeOriginShot or Runtime.SavePhase == "REBOUND_DEFENSE"
	Runtime.RunETA = runETA
	Runtime.DiveETA = diveETA
	Runtime.BallETA = intercept.time
	Runtime.RunMargin = intercept.time - runETA
	Runtime.DiveMargin = intercept.time - diveETA
	Runtime.SaveMethod = runCanCatch and "RUN_GRAB" or (diveFeasible and "DIVE_WINDOW" or "BLOCK")
	local highBall = relativeHeight >= CONFIG.HighBallRelative
	local cornerRatio = math.abs(stableInterceptX) / math.max(goal.halfWidth, 0.01)
	local cornerShot = cornerRatio >= CONFIG.CornerStartRatio
	local extremeCorner = cornerRatio >= CONFIG.ExtremeCornerRatio
	local cornerDiveNecessary = cornerShot and (
		lateralDistance > CONFIG.CornerRequiredLateral
		or (highBall and lateralDistance > CONFIG.EmergencyCenterRange)
	)
	local cornerLead = extremeCorner and CONFIG.ExtremeCornerMinimumLead or CONFIG.CornerMinimumLead
	if highBall and cornerShot then cornerLead = math.max(cornerLead, CONFIG.HighCornerMinimumLead) end
	if farOriginShot then cornerLead = math.min(cornerLead, CONFIG.FarCornerMaximumDiveLead) end
	local centerLimit = highBall and CONFIG.CenterHighBlockRange or CONFIG.CenterBlockRange
	if lateralDistance <= centerLimit then
		resetDiveCandidate()
		setSavePhase("SHOT_CONFIRMED")
		Runtime.SaveMethod = "BODY_GRAB"
		Runtime.State = "CENTER SHOT"
		Runtime.Action = highBall and "CENTER HIGH GRAB" or "CENTER HOLD + GRAB"
		Runtime.ShotUrgency = fastShot and "FAST CENTER" or (mediumShot and "CONTROLLED CENTER" or ((slowShot or groundMoveShot) and "SLOW CENTER" or "CENTER"))
		setWorldTarget(goal, target, "NO SIDE DIVE", true)
		return intercept, {
			keeperLocal = keeperLocal, ballLocal = ballLocal,
			lateralDistance = lateralDistance, runReach = runReach,
			diveReach = diveReach, eta = intercept.time,
			goalwardSpeed = goalwardSpeed, urgency = Runtime.ShotUrgency,
			confidence = Runtime.ShotConfidence, cornerRatio = cornerRatio,
			stableInterceptX = stableInterceptX,
		}
	end
	local slowResidual = currentDiveResidual
	local slowDynamicCommit = math.clamp(
		calculateAdaptiveDiveLead(
			goal,
			intercept.position,
			keeper,
			projectedKeeperX,
			side,
			slowResidual,
			diveReach,
			CONFIG.SlowShotDiveBuffer,
			diveProfile
		),
		slowCommitTime,
		CONFIG.SlowShotMaximumDiveLead
	)
	if cornerDiveNecessary then
		slowDynamicCommit = math.max(slowDynamicCommit, math.min(cornerLead, CONFIG.SlowShotMaximumDiveLead))
	end
	if farOriginShot then slowDynamicCommit = math.min(slowDynamicCommit, cornerShot and CONFIG.FarCornerMaximumDiveLead or CONFIG.FarShotMaximumDiveLead) end
	local slowNeedsDive = (slowShot or groundMoveShot) and not runCanCatch
		and intercept.time <= slowDynamicCommit
	local mediumResidual = currentDiveResidual
	local mediumDynamicCommit = math.clamp(
		calculateAdaptiveDiveLead(
			goal,
			intercept.position,
			keeper,
			projectedKeeperX,
			side,
			mediumResidual,
			diveReach,
			CONFIG.MediumShotDiveBuffer,
			diveProfile
		),
		CONFIG.DiveMinimumLead,
		CONFIG.MediumShotMaximumDiveLead
	)
	if cornerDiveNecessary then mediumDynamicCommit = math.max(mediumDynamicCommit, cornerLead) end
	if farOriginShot then mediumDynamicCommit = math.min(mediumDynamicCommit, cornerShot and CONFIG.FarCornerMaximumDiveLead or CONFIG.FarShotMaximumDiveLead) end
	local mediumNeedsDive = mediumShot and not runCanCatch and lateralDistance > catchRadius
		and intercept.time <= mediumDynamicCommit
	local cornerCommitLead = (slowShot or groundMoveShot) and slowDynamicCommit or cornerLead
	local cornerCommit = cornerDiveNecessary and intercept.time <= cornerCommitLead
	if cornerShot and Runtime.ShotUrgency ~= "EXTREME" and Runtime.ShotUrgency ~= "EMERGENCY" then
		Runtime.ShotUrgency = extremeCorner and "EXTREME CORNER" or "CORNER"
	end
	-- Langsame, flache Schüsse werden bis kurz vor dem Kontakt permanent neu
	-- verfolgt. Kein frühes Dive-Alignment: direkt zum aktuellen Fangpunkt
	-- laufen und Grab parallel aktiv lassen. Erst das Commit-Zeitfenster darunter
	-- darf anschließend in die normale Notfall-/Dive-Logik fallen.
	if (slowShot or groundMoveShot) and not slowNeedsDive then
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "RUN_GRAB"
		Runtime.State, Runtime.Action = "SLOW SHOT", "RUN + LIVE TRACK + GRAB"
		setWorldTarget(goal, target, "SLOW INTERCEPT", true)
		return intercept, {
			keeperLocal = keeperLocal, ballLocal = ballLocal,
			lateralDistance = lateralDistance,
			runReach = runReach + CONFIG.SlowShotRunReachBonus,
			diveReach = diveReach, eta = intercept.time,
			goalwardSpeed = goalwardSpeed, urgency = cornerShot and "CORNER TRACK" or "SLOW",
			confidence = Runtime.ShotConfidence,
		}
	end
	-- Normale Schüsse zwischen SLOW und FAST bleiben ebenfalls im kontrollierten
	-- Lauf-/Grab-Modus. Der Dive wird erst erlaubt, wenn die physisch benötigte
	-- Dive-Zeit aus aktueller Restdistanz und gelernter Dive-Geschwindigkeit
	-- erreicht ist. Dadurch verschwindet die frühere 55..69-Lücke.
	if mediumShot and not highBall and not mediumNeedsDive then
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "RUN_GRAB"
		Runtime.State, Runtime.Action = "CONTROLLED SHOT", "RUN + LIVE TRACK + GRAB"
		Runtime.ShotUrgency = cornerShot and "CORNER TRACK" or "CONTROLLED"
		setWorldTarget(goal, target, "CONTROLLED INTERCEPT", true)
		return intercept, {
			keeperLocal = keeperLocal, ballLocal = ballLocal,
			lateralDistance = lateralDistance,
			runReach = runReach + CONFIG.MediumShotRunReachBonus,
			diveReach = diveReach, eta = intercept.time,
			goalwardSpeed = goalwardSpeed, urgency = Runtime.ShotUrgency,
			confidence = Runtime.ShotConfidence, cornerRatio = cornerRatio,
			stableInterceptX = stableInterceptX,
		}
	end
	local closeTimeShot = intercept.time <= CONFIG.FastShotImmediateTime
	local urgentShot = fastShot or closeTimeShot
	local emergencyShot = intercept.time <= CONFIG.EmergencyDiveTime
	local extremeEmergency = intercept.time <= CONFIG.ExtremeEmergencyTime
	-- Auf kurzen/schnellen Schüssen zählt die Fangreichweite nicht als kostenlose
	-- Laufstrecke. Ab kleiner Seitendifferenz darf RUN weiter lösen; darüber
	-- wird der native Dive schon vorbereitet bzw. sofort ausgelöst.
	local requiredDiveDistance = cornerShot and CONFIG.EmergencyCenterRange or CONFIG.FastRunOnlyLateral
	local controlledNeedsDive = slowNeedsDive or mediumNeedsDive
	local requireFastDive = (urgentShot or controlledNeedsDive or cornerCommit)
		and not runCanCatch and lateralDistance > requiredDiveDistance
	if slowNeedsDive then Runtime.ShotUrgency = "SLOW COMMIT" end
	if mediumNeedsDive then Runtime.ShotUrgency = "CONTROLLED COMMIT" end
	if cornerCommit then Runtime.ShotUrgency = extremeCorner and "EXTREME CORNER COMMIT" or "CORNER COMMIT" end

	if runCanCatch and not requireFastDive then
		setSavePhase("RUN_INTERCEPT")
		Runtime.SaveMethod = "RUN_GRAB"
		Runtime.Action = urgentShot and "FAST CENTER BLOCK" or "RUN"
		setWorldTarget(goal, target, urgentShot and "FAST RUN + GRAB" or "RUN INTERCEPT", true)
	else
		-- Physische Kontaktzeit: Ab JETZT benötigte Dive-Strecke geteilt durch
		-- tatsächlich gelernte Dive-Geschwindigkeit. Keine hypothetische volle
		-- Laufstrecke und Dive-Strecke mehr gleichzeitig anrechnen.
		local diveLead = math.clamp(
			calculateAdaptiveDiveLead(
				goal,
				intercept.position,
				keeper,
				projectedKeeperX,
				side,
				currentDiveResidual,
				diveReach,
				CONFIG.DiveContactBuffer,
				diveProfile
			),
			CONFIG.DiveMinimumLead,
			CONFIG.DiveMaximumLead
		)
		if mediumNeedsDive then diveLead = math.max(diveLead, mediumDynamicCommit) end
		if slowNeedsDive then diveLead = math.max(diveLead, slowDynamicCommit) end
		if fastShot and not farOriginShot then
			diveLead = math.min(CONFIG.DiveMaximumLead, math.max(diveLead + CONFIG.FastShotExtraLead, CONFIG.FastShotMinimumDiveLead))
		end
		if extremeSpeed and not farOriginShot then
			diveLead = math.min(CONFIG.DiveMaximumLead, math.max(diveLead + CONFIG.FastShotExtraLead * 0.55, CONFIG.ExtremeSpeedMinimumDiveLead))
		end
		if lateralDistance >= CONFIG.FarShotDistance and not (slowShot or groundMoveShot) then
			diveLead = math.max(diveLead, CONFIG.FarShotMinimumLead)
		end
		if cornerDiveNecessary then
			diveLead = math.min(CONFIG.DiveMaximumLead, math.max(diveLead + CONFIG.CornerDiveExtraLead, cornerLead))
		end
		if farOriginShot then
			diveLead = math.min(diveLead, cornerShot and CONFIG.FarCornerMaximumDiveLead or CONFIG.FarShotMaximumDiveLead)
		elseif closeOriginShot then
			diveLead = math.min(diveLead, CONFIG.CloseShotMaximumDiveLead)
		end
		Runtime.DiveETA = diveLead
		if diveFeasible then
			setSavePhase("DIVE_ARMED")
			Runtime.SaveMethod = "DIVE_PREP"
			local launchLateral = (closeTimeShot or controlledNeedsDive or cornerCommit) and keeperLocal.X
				or stableInterceptX - side * math.max(0, diveReach - catchRadius * 0.5)
			local launchTarget = goalToWorld(goal, launchLateral, goal.homeDepth, goal.bottomY)
			Runtime.Action = cornerShot and "CORNER DIVE READY" or (urgentShot and "FAST DIVE READY" or "DIVE ALIGN")
			setWorldTarget(goal, launchTarget, cornerShot and "CORNER ALIGN" or (urgentShot and "FAST SHOT" or "DIVE ALIGN"), false)
			local highBallLead = math.min(CONFIG.DiveMaximumLead, diveLead + 0.18)
			local launchNow = extremeEmergency or emergencyShot or controlledNeedsDive or cornerCommit
				or intercept.time <= diveLead + CONFIG.DiveArrivalTolerance
				or (highBall and intercept.time <= highBallLead)
			if launchNow and predictionTrusted and not normalCatchSoon
				and lateralDistance > CONFIG.EmergencyCenterRange and Runtime.DivedTrajectoryId ~= Runtime.TrajectoryId then
				local immediateCommit = fastShot or extremeSpeed or emergencyShot or extremeEmergency
				if confirmDiveCandidate(side, immediateCommit, intercept.time) then
					local diveReason = extremeCorner and "EXTREME CORNER"
						or (cornerShot and highBall and "HIGH CORNER")
						or (cornerShot and "CORNER")
						or (mediumNeedsDive and "CONTROLLED CONTACT")
						or (slowNeedsDive and "SLOW LAST CHANCE")
						or (extremeEmergency and "EXTREME")
						or (emergencyShot and "CLOSE")
						or (fastShot and "FAST")
						or (highBall and "HIGH")
						or "REACH"
					local dived = performDive(goal, side, diveReason, intercept.position.Y, diveTier)
					if dived then Runtime.SaveMethod = "DIVE" end
					Runtime.Action = dived and "DIVE" or "FAST BLOCK"
				else
					Runtime.Action = "DIVE DIRECTION VERIFY"
				end
			end
		else
			setSavePhase("SHOT_CONFIRMED")
			Runtime.SaveMethod = "BLOCK"
			Runtime.Action = "EMERGENCY BLOCK"
			setWorldTarget(goal, target, "BLOCK", true)
			if (emergencyShot or extremeEmergency) and predictionTrusted and not normalCatchSoon and lateralDistance > CONFIG.EmergencyCenterRange
				and Runtime.DivedTrajectoryId ~= Runtime.TrajectoryId then
				local immediateCommit = fastShot or extremeSpeed or emergencyShot or extremeEmergency
				if confirmDiveCandidate(side, immediateCommit, intercept.time) then
					local dived = performDive(goal, side, extremeCorner and "EXTREME CORNER" or (cornerShot and "CORNER" or (extremeEmergency and "EXTREME" or "EMERGENCY")), intercept.position.Y, diveTier)
					if dived then Runtime.Action, Runtime.SaveMethod = "DIVE", "DIVE" end
				else
					Runtime.Action = "DIVE DIRECTION VERIFY"
				end
			end
		end
	end
	return intercept, {
		keeperLocal = keeperLocal, ballLocal = ballLocal,
		lateralDistance = lateralDistance, runReach = runReach,
		diveReach = diveReach, eta = intercept.time,
		goalwardSpeed = goalwardSpeed, urgency = Runtime.ShotUrgency,
		rawGoalwardSpeed = rawGoalwardSpeed, gateSpeed = gateSpeed, gateConfidence = gateConfidence,
		confidence = Runtime.ShotConfidence, cornerRatio = cornerRatio,
		stableInterceptX = stableInterceptX, projectedKeeperX = projectedKeeperX,
		centralLateralDistance = centralLateralDistance,
		corridorLateralDistance = corridorLateralDistance,
	}
end

--==============================================================
-- DIAGNOSTICS
--==============================================================

local function updateDiagnostics(now)
	if now - Runtime.LastDiagnostics < CONFIG.DiagnosticsInterval then return end
	Runtime.LastDiagnostics = now
	local goal = Runtime.DefendedGoal
	local zoneState = goal and goal.zone and "LIVE" or (goal and "FALLBACK" or "FAIL")
	local keeper = getKeeperPosition()
	local keeperDepth = goal and keeper and goalToLocal(goal, keeper).Z or nil
	local targetDepth = goal and Runtime.WorldTarget and goalToLocal(goal, Runtime.WorldTarget).Z or nil
	local depthText = keeperDepth and targetDepth and string.format("D %.1f>%.1f", keeperDepth, targetDepth) or "D --"
	local goalName = Runtime.DefendedGoalName or "NO-GOAL"
	local zoneName = Runtime.DefendedZoneObject and Runtime.DefendedZoneObject.Name or "NO-ZONE"
	local impact = Runtime.PredictedGoalImpact
	local impactText = impact and impact.localPosition and string.format(
		"I %.1f/%.1f %.2fs",
		impact.localPosition.X,
		impact.position.Y,
		Runtime.BallETA < math.huge and Runtime.BallETA or 0
	) or "I --"
	Labels.Status.Text = string.format("%s  •  %s  •  %s", Runtime.SavePhase, Runtime.State, Runtime.Action)
	Labels.Status.TextColor3 = Runtime.HoldingBall and COLORS.GREEN
		or (Runtime.State == "CALIBRATION FAILED" and COLORS.RED or COLORS.TEXT)
	Labels.Target.Text = string.format(
		"T%d %s %.0f%%  •  %s  •  %s",
		Runtime.TrajectoryId,
		Tracker.Model,
		Runtime.PredictionConfidence * 100,
		impactText,
		Runtime.Event
	)
	Labels.Telemetry.Text = string.format(
		"%s  |  %s/%s  |  C %s  |  D %s/P%d  |  %s  |  %s",
		depthText,
		goalName,
		zoneName,
		Runtime.DiveContactKind,
		Runtime.DiveTimingModel,
		Runtime.DiveVerticalInputPolarity,
		Runtime.RecoveryRequired and ("RETURN " .. Runtime.RecoveryReason) or "ZONE READY",
		Runtime.PositionFault ~= "NONE" and Runtime.PositionFault or ("ZONE " .. zoneState)
	)
end

--==============================================================
-- PHYSIK LESEN NACH DER SIMULATION
--==============================================================

local lastGoalRefresh = -100

RunService.PostSimulation:Connect(function()
	local now = os.clock()
	if now - Runtime.LastControlRepair >= CONFIG.ControlRepairInterval then
		Runtime.LastControlRepair = now
		resolveModulesAndHooks()
	end
	if now - lastGoalRefresh >= CONFIG.GoalRefreshInterval then
		lastGoalRefresh = now
		refreshGoals()
	end
	local ball = sampleBall(now)
	local keeper = getKeeperPosition()
	if keeper then
		updateKeeperLearning(now, keeper)
		updateDiveLifecycle(now, keeper)
	end
	if not ball or not keeper then
		Runtime.State = not keeper and "POSITION FAULT" or "NO BALL"
		Runtime.Action = "STOP"
		Runtime.SaveMethod = not keeper and "FAULT" or "WAIT"
		if not keeper then setSavePhase("FAULT", "KEEPER POSITION INVALID") end
		if not ball then
			Runtime.PreparedGrabETA = math.huge
			Runtime.PreparedGrabUntil = 0
			Runtime.PredictedGoalImpact = nil
		end
		Runtime.RunETA, Runtime.DiveETA, Runtime.BallETA = math.huge, math.huge, math.huge
		local lifecycleLocked = Runtime.Diving
			or Runtime.SavePhase == "CONTACT_WINDOW"
			or Runtime.SavePhase == "GETTING_UP"
		if keeper and not ball and Runtime.RecoveryRequired and Runtime.DefendedGoal and not lifecycleLocked then
			local goal = Runtime.DefendedGoal
			local recoveryTarget, outsideSafeZone = postDiveRecoveryTarget(goal, keeper)
			local recoveryDistance = horizontal(recoveryTarget - keeper).Magnitude
			if not outsideSafeZone and recoveryDistance <= CONFIG.RecoveryArrivalDistance
				and horizontal(Runtime.LastKeeperVelocity).Magnitude <= CONFIG.RecoveryHomeSpeed then
				Runtime.RecoveryRequired = false
				Runtime.RecoveryReason = "NONE"
				setSavePhase("READY", "RECOVERY COMPLETE / NO BALL")
				clearWorldTarget()
			else
				Runtime.State, Runtime.Action, Runtime.SaveMethod = "RECOVER HOME", "BALL LOST", "RECOVERY"
				setSavePhase(outsideSafeZone and "RECOVER_TO_ZONE" or "RECOVER_TO_HOME")
				setWorldTarget(goal, recoveryTarget, outsideSafeZone and "RETURN TO ZONE / NO BALL" or "POST-DIVE RETURN / NO BALL", false)
			end
		else
			clearWorldTarget()
		end
		updateDiagnostics(now)
		return
	end
	updateMovementHealth(now, keeper)
	updateController(now, keeper, ball)
	updateDiagnostics(now)
end)

--==============================================================
-- GUI BUTTONS
--==============================================================

Buttons.Bot.MouseButton1Click:Connect(function()
	Options.Bot = not Options.Bot
	Buttons.Bot.Text = "BOT " .. (Options.Bot and "ON" or "OFF")
	Buttons.Bot.BackgroundColor3 = Options.Bot and COLORS.GREEN or COLORS.RED
	if not Options.Bot then clearWorldTarget() end
end)

Buttons.Grab.MouseButton1Click:Connect(function()
	Options.AutoGrab = not Options.AutoGrab
	Buttons.Grab.Text = "GRAB " .. (Options.AutoGrab and "ON" or "OFF")
	Buttons.Grab.BackgroundColor3 = Options.AutoGrab and COLORS.ORANGE or COLORS.RED
	Runtime.GrabFSM = Options.AutoGrab and "ARMED" or "OFF"
	if not Options.AutoGrab then fireGrab(false) end
end)

Buttons.Dive.MouseButton1Click:Connect(function()
	Options.AutoDive = not Options.AutoDive
	Buttons.Dive.Text = "DIVE " .. (Options.AutoDive and "ON" or "OFF")
	Buttons.Dive.BackgroundColor3 = Options.AutoDive and COLORS.GREEN or COLORS.RED
end)

Buttons.Recalibrate.MouseButton1Click:Connect(function()
	clearWorldTarget()
	resetDefendedGoalLock("MANUAL RECALIBRATION")
	resetKeeperPositionSource()
	Runtime.InputPolarity = 1
	Runtime.InputCalibrationState = "PENDING"
	Runtime.WrongDirectionSamples = 0
	Runtime.CorrectDirectionSamples = 0
	Runtime.MovementFaultUntil = 0
	refreshGoals()
	discoverBall(true)
	refreshGrabIndicators()
	local keeper = getKeeperPosition()
	if keeper then getDefendedGoal(keeper) end
	Runtime.Event = Runtime.CalibrationOK and ("MANUAL GOAL " .. Runtime.GoalMode) or "MANUAL CALIBRATION FAILED"
end)

--==============================================================
-- INITIALISIERUNG / RESPAWN / CLEANUP
--==============================================================

local BallAnimationConnection = nil

local function playerFromSignalArguments(...)
	for _, value in ipairs({...}) do
		if typeof(value) == "Instance" then
			if value:IsA("Player") then return value end
			local model = value:IsA("Model") and value or value:FindFirstAncestorOfClass("Model")
			if model then
				local player = Players:GetPlayerFromCharacter(model)
				if player then return player end
			end
		elseif typeof(value) == "number" then
			local player = Players:GetPlayerByUserId(math.floor(value + 0.5))
			if player then return player end
		elseif typeof(value) == "string" then
			local player = Players:FindFirstChild(value)
			if player and player:IsA("Player") then return player end
		end
	end
	return Runtime.Possessor
end

local function connectPassiveBallAnimationSignal()
	if BallAnimationConnection then
		BallAnimationConnection:Disconnect()
		BallAnimationConnection = nil
	end
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local remote = remoteFolder and remoteFolder:FindFirstChild("BallAnimation")
	if not remote or not remote:IsA("RemoteEvent") then return end
	BallAnimationConnection = remote.OnClientEvent:Connect(function(...)
		local player = playerFromSignalArguments(...)
		if player and player ~= LocalPlayer then
			Runtime.IntentReleasePlayer = player
			Runtime.IntentReleaseUntil = os.clock() + CONFIG.PreShotReleaseMemory
			Runtime.IntentState = "RELEASE"
			Runtime.Event = "SERVER KICK ANIMATION"
		end
	end)
end

resolveModulesAndHooks()
refreshGoals()
refreshGrabIndicators()
discoverBall(true)
connectPassiveBallAnimationSignal()
local initialKeeperPosition = getKeeperPosition()
if initialKeeperPosition then getDefendedGoal(initialKeeperPosition) end

LocalPlayer.CharacterAdded:Connect(function()
	resetDefendedGoalLock("RESPAWN RECALIBRATION")
	resetKeeperPositionSource()
	Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
	Runtime.WorldTarget = nil
	Runtime.AllowOutsidePosts = false
	Runtime.TargetArrived = false
	Runtime.BoundaryStuckCount = 0
	Runtime.BoundaryRetreatUntil = 0
	Runtime.BoundaryRetreatTarget = nil
	Runtime.WrongDirectionSamples = 0
	Runtime.CorrectDirectionSamples = 0
	Runtime.InputPolarity = 1
	Runtime.InputCalibrationState = "PENDING"
	Runtime.MovementFaultUntil = os.clock() + 0.55
	Runtime.HoldingBall = false
	Runtime.Diving = false
	Runtime.DiveToken += 1
	Runtime.SavePhase = "CALIBRATING"
	Runtime.SavePhaseSince = os.clock()
	Runtime.DiveMinimumEndAt = 0
	Runtime.DiveMaximumEndAt = 0
	Runtime.DiveStillSince = nil
	Runtime.DiveFirstMotionAt = nil
	Runtime.DiveMotionSamples = {}
	Runtime.DivePreviousBallVelocity = nil
	Runtime.DiveContactDetected = false
	Runtime.DiveContactKind = "NONE"
	Runtime.DiveContactPosition = nil
	Runtime.ContactWindowUntil = 0
	Runtime.GetUpEarliest = 0
	Runtime.GetUpDeadline = 0
	Runtime.RecoveryRequired = false
	Runtime.RecoveryReason = "NONE"
	Runtime.InputLearningPausedUntil = 0
	Runtime.ReboundUntil = 0
	Runtime.DivedTrajectoryId = -1
	Runtime.LastKeeperPosition = nil
	Runtime.StableInterceptX = nil
	Runtime.StableInterceptY = nil
	Runtime.StableInterceptTime = nil
	Runtime.StableInterceptShotId = -1
	Runtime.ShotOriginPosition = nil
	Runtime.ShotDistanceClass = "UNKNOWN"
	Runtime.Possessor = nil
	Runtime.PossessorConfidence = 0
	Runtime.PossessorStablePlayer = nil
	Runtime.PossessorStableSince = 0
	Runtime.AnticipationX = nil
	Runtime.AnticipationPlayer = nil
	Runtime.AnticipationActive = false
	Runtime.AnticipationWeight = 0
	Runtime.IntentPlayer = nil
	Runtime.IntentState = "IDLE"
	Runtime.IntentConfidence = 0
	Runtime.IntentAimX = nil
	Runtime.IntentAimY = nil
	Runtime.IntentEvidence = "NONE"
	Runtime.IntentStableSince = 0
	Runtime.IntentUntil = 0
	Runtime.IntentReleasePlayer = nil
	Runtime.IntentReleaseUntil = 0
	Runtime.VirtualGateGoal = nil
	Runtime.VirtualGateLastDepth = nil
	Runtime.VirtualGateLastTime = nil
	Runtime.VirtualGateLastCrossDepth = nil
	Runtime.VirtualGateLastCrossTime = nil
	Runtime.VirtualGateCrossCount = 0
	Runtime.VirtualGateSpeed = 0
	Runtime.VirtualGateConfidence = 0
	Runtime.VirtualGateLastEvent = -100
	Runtime.PredictionConfidence = 0
	Runtime.PredictionUncertainty = 1
	Runtime.PredictionModelSince = 0
	Runtime.PredictionLastModel = "CV"
	Runtime.RunETA, Runtime.DiveETA, Runtime.BallETA = math.huge, math.huge, math.huge
	Runtime.SaveMethod = "WAIT"
	Runtime.DiveCandidateFrames = 0
	Runtime.DiveCandidateSide = 0
	Runtime.ActiveDiveProfile = nil
	Runtime.DiveCommandedTier = nil
	Runtime.DiveStartHitboxOffsetY = nil
	Runtime.DiveHitboxPeakDelta = -math.huge
	Runtime.DiveHitboxTroughDelta = math.huge
	Runtime.DiveHitboxBinsThisDive = {}
	Runtime.DiveHitboxSampleCount = 0
	Runtime.PreparedGrabETA = math.huge
	Runtime.PreparedGrabUntil = 0
	Runtime.PredictedGoalImpact = nil
	Runtime.BallSourceChanged = false
	Tracker.Ball, Tracker.PhysicsBall, Tracker.Position = nil, nil, nil
	Tracker.LastTime = 0
	Tracker.MeasurementPosition = nil
	Tracker.FilterPosition = nil
	Tracker.FilterVelocity = Vector3.zero
	Tracker.FilterAcceleration = Vector3.zero
	Tracker.LastFilterTime = 0
	Tracker.MeasurementAge = 0
	Tracker.NetworkPing = 0
	Tracker.Dataset = nil
	Tracker.DatasetModel = nil
	Tracker.CurveAcceleration = Vector3.zero
	Tracker.CurveDirection = Vector3.zero
	Tracker.CurveFrames = 0
	Tracker.CurveConfirmed = false
	Tracker.CurveVelocity = Vector3.zero
	Tracker.UpForceVelocity = Vector3.zero
	Tracker.RawVelocity = Vector3.zero
	Tracker.Velocity = Vector3.zero
	Tracker.Acceleration = Vector3.zero
	Tracker.LastPredictionState = nil
	Tracker.History = {}
	Tracker.Measurements = {}
	Tracker.LastAcceptedVelocity = Vector3.zero
	Tracker.CurvePredictionCacheStamp = -1
	Tracker.CurvePredictionCache = nil
	task.delay(0.5, function()
		resetKeeperPositionSource()
		resolveModulesAndHooks()
		refreshGoals()
		refreshGrabIndicators()
		discoverBall(true)
		connectPassiveBallAnimationSignal()
	end)
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	clearWorldTarget()
	Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
	resetDefendedGoalLock("TEAM CHANGED")
	resetKeeperPositionSource()
	Runtime.InputPolarity = 1
	Runtime.InputCalibrationState = "PENDING"
	Runtime.WrongDirectionSamples = 0
	Runtime.CorrectDirectionSamples = 0
	Runtime.MovementFaultUntil = 0
	Runtime.Diving = false
	Runtime.DiveToken += 1
	Runtime.RecoveryRequired = false
	Runtime.RecoveryReason = "NONE"
	Runtime.InputLearningPausedUntil = 0
	Runtime.ReboundUntil = 0
	Runtime.DivePreviousBallVelocity = nil
	Runtime.DiveFirstMotionAt = nil
	Runtime.DiveMotionSamples = {}
	Runtime.DiveCommandedTier = nil
	Runtime.DiveStartHitboxOffsetY = nil
	Runtime.DiveHitboxBinsThisDive = {}
	Runtime.DiveHitboxSampleCount = 0
	setSavePhase("CALIBRATING", "TEAM CHANGED")
end)

Gui.Destroying:Connect(function()
	pcall(function() RunService:UnbindFromRenderStep("SpecialGKBotV23Movement") end)
	Runtime.ForcedMoveVector, Runtime.ForcedMoveOwner = nil, nil
	if BallAnimationConnection then
		BallAnimationConnection:Disconnect()
		BallAnimationConnection = nil
	end
	fireGrab(false)
end)

print("[SPECIAL GK BOT V23.6] LOADED | cached curve prediction + learned dive-hitbox contact timing")
