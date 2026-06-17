const SUPABASE_URL = "https://cwhhekrtqkwaaabztmrq.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3aGhla3J0cWt3YWFhYnp0bXJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxODI5ODIsImV4cCI6MjA5MDc1ODk4Mn0.qTKc-PkfTuyf7tRVkotAmLRKwwNu_P_LXmFc7pZ0Csk";

const routes = ["/", "/home", "/create", "/join", "/mypage", "/admin"];
const protectedRoutes = ["/home", "/create", "/join", "/mypage", "/admin"];

const state = {
  mode: "signin",
  session: null,
  userId: null,
  profile: null,
  isAdmin: false,
  requestedRoute: null,
  isLoadingClues: false,
  clues: [],
  participations: [],
};

const categoryLabels = {
  adventure: "탐험",
  quiz: "퀴즈",
  education: "교육",
  life_help: "생활",
  promotion: "프로모션",
  workshop: "워크숍",
  broadcast: "방송",
};

const visibleStatuses = ["active", "approved"];
const pendingStatuses = ["pending_approval", "draft"];
const defaultLocation = {
  lat: 37.5666,
  lng: 126.9784,
  label: "서울시청",
};

const els = {
  landingView: document.querySelector("[data-view='landing']"),
  dashboardView: document.querySelector("[data-view='dashboard']"),
  publicNav: document.querySelector(".public-nav"),
  appNav: document.querySelector(".app-nav"),
  authPanel: document.querySelector(".auth-panel"),
  form: document.querySelector("#authForm"),
  tabs: document.querySelectorAll(".tab"),
  submitButton: document.querySelector("#submitButton"),
  modeSwitchButton: document.querySelector("#modeSwitchButton"),
  resetPasswordButton: document.querySelector("#resetPasswordButton"),
  togglePasswordButton: document.querySelector(".toggle-password"),
  message: document.querySelector("#authMessage"),
  emailInput: document.querySelector("#email"),
  passwordInput: document.querySelector("#password"),
  nicknameInput: document.querySelector("#nickname"),
  adminToggle: document.querySelector("#adminToggle"),
  logoutButton: document.querySelector("#logoutButton"),
  homeClues: document.querySelector("#homeClues"),
  joinClues: document.querySelector("#joinClues"),
  adminClues: document.querySelector("#adminClues"),
  discoverMap: document.querySelector("#discoverMap"),
  createMap: document.querySelector("#createMap"),
  selectedLocationText: document.querySelector("#selectedLocationText"),
  adminDenied: document.querySelector("#adminDenied"),
  adminBoard: document.querySelector("#adminBoard"),
  createForm: document.querySelector("#createForm"),
  profileForm: document.querySelector("#profileForm"),
  userName: document.querySelector("#userName"),
  userEmail: document.querySelector("#userEmail"),
  userAvatar: document.querySelector("#userAvatar"),
  approvedCount: document.querySelector("#approvedCount"),
  pendingCount: document.querySelector("#pendingCount"),
  joinedCount: document.querySelector("#joinedCount"),
  toast: document.querySelector("#toast"),
};

let supabaseClient = null;
let supabaseInitPromise = null;
let toastTimer = null;
let leafletInitPromise = null;
let discoverMap = null;
let discoverLayer = null;
let createMap = null;
let createMarker = null;
let createRadiusCircle = null;
let mapsInitialized = false;

const createLocation = {
  lat: defaultLocation.lat,
  lng: defaultLocation.lng,
};

function loadScript(src) {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = src;
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
}

function loadStylesheet(href) {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`link[href="${href}"]`)) {
      resolve();
      return;
    }

    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    link.onload = resolve;
    link.onerror = reject;
    document.head.appendChild(link);
  });
}

async function ensureLeaflet() {
  if (window.L) return window.L;
  if (leafletInitPromise) return leafletInitPromise;

  leafletInitPromise = (async () => {
    await loadStylesheet("https://unpkg.com/leaflet@1.9.4/dist/leaflet.css");
    await loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js");
    if (!window.L) throw new Error("Leaflet load failed");
    return window.L;
  })();

  return leafletInitPromise;
}

async function ensureSupabase() {
  if (supabaseClient) return supabaseClient;
  if (supabaseInitPromise) return supabaseInitPromise;

  supabaseInitPromise = (async () => {
    if (!window.supabase) {
      try {
        await loadScript("https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2");
      } catch (_error) {
        await loadScript("https://unpkg.com/@supabase/supabase-js@2");
      }
    }

    if (!window.supabase) {
      throw new Error("Supabase SDK load failed");
    }

    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    });

    await syncSession();
    return supabaseClient;
  })();

  return supabaseInitPromise;
}

function initSupabase() {
  ensureSupabase().catch(() => {
    setMessage("Supabase SDK를 불러오지 못했습니다. 네트워크 연결을 확인해주세요.", "error");
  });
}

function initialRoute() {
  const routeFromQuery = new URLSearchParams(window.location.search).get("route");
  if (routes.includes(routeFromQuery)) {
    history.replaceState({}, "", routeFromQuery);
    return routeFromQuery;
  }

  return window.location.pathname;
}

async function syncSession() {
  if (!supabaseClient) return;

  const { data } = await supabaseClient.auth.getSession();
  if (data.session?.user) {
    await applyUserSession(data.session.user);
    goTo(state.requestedRoute || "/home", true);
  }

  supabaseClient.auth.onAuthStateChange(async (_event, session) => {
    if (session?.user) {
      await applyUserSession(session.user);
      goTo(state.requestedRoute || "/home", true);
    } else {
      state.session = null;
      state.userId = null;
      state.profile = null;
      state.isAdmin = false;
    }
  });
}

async function applyUserSession(user) {
  const nickname = user.user_metadata?.nickname || user.email?.split("@")[0] || "런클루 크루";
  state.userId = user.id;
  state.session = {
    name: nickname,
    email: user.email || "crew@runclue.app",
  };

  await loadProfile();
  await loadClues();
  updateUserChrome();
}

function applyDemoSession() {
  state.userId = null;
  state.profile = null;
  state.session = {
    name: "데모 크루",
    email: "demo@runclue.app",
  };
  state.clues = [
    {
      id: "demo-clue-1",
      title: "성수 카페 시그니처 찾기",
      place: "성수동 12길",
      category: "adventure",
      capacity: 8,
      joined: 5,
      joinedByMe: false,
      status: "active",
      description: "힌트를 따라 매장에 방문하고 시그니처 메뉴 사진을 인증합니다.",
      latitude: 37.5446,
      longitude: 127.0557,
      radiusMeters: 50,
    },
  ];
  updateUserChrome();
  goTo("/home", true);
  showToast("데모 세션으로 앱 화면을 열었습니다.");
}

function updateUserChrome() {
  const name = state.profile?.nickname || state.session?.name || "런클루 크루";
  const email = state.session?.email || "demo@runclue.app";
  els.userName.textContent = name;
  els.userEmail.textContent = email;
  els.userAvatar.textContent = name.trim().charAt(0).toUpperCase() || "R";
  document.querySelector("#profileNickname").value = name;
  document.querySelector("#profileBio").value = state.profile?.bio || "";
  els.adminToggle.checked = state.isAdmin;
}

function setMode(nextMode) {
  state.mode = nextMode;
  const isSignup = state.mode === "signup";

  els.authPanel.classList.toggle("signup-mode", isSignup);
  els.tabs.forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.mode === state.mode);
  });

  els.nicknameInput.required = isSignup;
  els.submitButton.textContent = isSignup ? "회원가입" : "크루 합류하기";
  els.modeSwitchButton.textContent = isSignup ? "로그인" : "회원가입";
  els.resetPasswordButton.hidden = isSignup;
  els.passwordInput.autocomplete = isSignup ? "new-password" : "current-password";
  setMessage("");
}

function setMessage(text, type = "") {
  els.message.textContent = text;
  els.message.className = `auth-message ${type}`.trim();
}

function setLoading(isLoading) {
  els.submitButton.disabled = isLoading;
  els.submitButton.textContent = isLoading
    ? "처리 중..."
    : state.mode === "signup"
      ? "회원가입"
      : "크루 합류하기";
}

function friendlyError(error, action) {
  const raw = error?.message || String(error);

  if (raw.includes("Invalid login credentials") || raw.includes("invalid_credentials")) {
    return "아이디 또는 비밀번호가 올바르지 않습니다.";
  }
  if (raw.includes("Email not confirmed") || raw.includes("email_not_confirmed")) {
    return "가입은 되었지만 Supabase 이메일 확인 설정 때문에 로그인이 막혀 있습니다.";
  }
  if (raw.includes("User already registered")) {
    return "이미 가입된 아이디입니다. 로그인을 시도해주세요.";
  }
  if (raw.includes("Failed to fetch") || raw.includes("NetworkError")) {
    return `${action} 실패: 인터넷 연결을 확인해주세요.`;
  }

  return `${action} 실패: ${raw}`;
}

async function loadProfile() {
  if (!supabaseClient || !state.userId) return;

  let { data, error } = await supabaseClient
    .from("profiles")
    .select("id,nickname,avatar_url,bio,role")
    .eq("id", state.userId)
    .maybeSingle();

  if (error) throw error;

  if (!data) {
    const fallbackNickname = state.session?.name || "런클루 크루";
    const insertResult = await supabaseClient
      .from("profiles")
      .insert({ id: state.userId, nickname: fallbackNickname })
      .select("id,nickname,avatar_url,bio,role")
      .single();

    if (insertResult.error) throw insertResult.error;
    data = insertResult.data;
  }

  state.profile = data;
  state.isAdmin = data?.role === "admin";
  if (data?.nickname) {
    state.session.name = data.nickname;
  }
}

async function loadClues() {
  if (!supabaseClient || !state.userId) return;

  state.isLoadingClues = true;
  try {
    const baseColumns = "id,creator_id,title,description,category,status,max_participants,current_participants,address,thumbnail_url,reward_type,reward_value,created_at";
    const locationColumns = `${baseColumns},center_latitude,center_longitude,center_address,radius_meters`;
    const [cluesResult, participationResult] = await Promise.all([
      selectClues(locationColumns, baseColumns),
      supabaseClient
        .from("participations")
        .select("id,clue_id,status,created_at")
        .eq("user_id", state.userId),
    ]);

    if (cluesResult.error) throw cluesResult.error;
    if (participationResult.error) throw participationResult.error;

    const joinedIds = new Set((participationResult.data || []).map((item) => item.clue_id));
    state.participations = participationResult.data || [];
    state.clues = (cluesResult.data || []).map((row) => normalizeClue(row, joinedIds));
  } finally {
    state.isLoadingClues = false;
  }
}

async function selectClues(primaryColumns, fallbackColumns) {
  let result = await supabaseClient
    .from("clues")
    .select(primaryColumns)
    .order("created_at", { ascending: false })
    .limit(100);

  if (result.error && /center_|radius_meters|schema cache|column/i.test(result.error.message || "")) {
    result = await supabaseClient
      .from("clues")
      .select(fallbackColumns)
      .order("created_at", { ascending: false })
      .limit(100);
  }

  return result;
}

function normalizeClue(row, joinedIds = new Set()) {
  const latitude = toNumber(row.center_latitude);
  const longitude = toNumber(row.center_longitude);

  return {
    id: row.id,
    creatorId: row.creator_id,
    title: row.title || "제목 없음",
    place: row.center_address || row.address || "온라인/장소 미정",
    category: row.category || "adventure",
    capacity: row.max_participants || 99,
    joined: row.current_participants || 0,
    joinedByMe: joinedIds.has(row.id),
    status: row.status || "draft",
    description: row.description || "설명이 아직 없습니다.",
    rewardType: row.reward_type,
    rewardValue: row.reward_value,
    createdAt: row.created_at,
    latitude,
    longitude,
    radiusMeters: toNumber(row.radius_meters) || 50,
  };
}

function toNumber(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function isVisibleClue(clue) {
  return visibleStatuses.includes(clue.status);
}

function isPendingClue(clue) {
  return pendingStatuses.includes(clue.status);
}

async function handleSubmit(event) {
  event.preventDefault();

  const email = els.emailInput.value.trim();
  const password = els.passwordInput.value;
  const nickname = els.nicknameInput.value.trim();

  if (state.mode === "signup" && nickname.length < 2) {
    setMessage("닉네임은 2자 이상이어야 합니다.", "error");
    return;
  }

  setLoading(true);
  setMessage("");

  try {
    const client = await ensureSupabase();

    if (state.mode === "signup") {
      const { data, error } = await client.auth.signUp({
        email,
        password,
        options: {
          data: { nickname },
        },
      });
      if (error) throw error;
      if (data.session?.user) {
        await applyUserSession(data.session.user);
      } else {
        const loginResult = await client.auth.signInWithPassword({ email, password });
        if (loginResult.error) throw loginResult.error;
        await applyUserSession(loginResult.data.user);
      }
    } else {
      const { data, error } = await client.auth.signInWithPassword({ email, password });
      if (error) throw error;
      await applyUserSession(data.user);
    }

    setMessage("로그인이 완료되었습니다.", "success");
    goTo("/home", true);
  } catch (error) {
    setMessage(friendlyError(error, state.mode === "signup" ? "회원가입" : "로그인"), "error");
  } finally {
    setLoading(false);
  }
}

async function handlePasswordReset() {
  const email = els.emailInput.value.trim() || window.prompt("가입한 아이디를 입력해주세요.");
  if (!email) return;

  try {
    const client = await ensureSupabase();
    const { error } = await client.auth.resetPasswordForEmail(email, {
      redirectTo: window.location.origin,
    });
    if (error) throw error;
    setMessage("비밀번호 재설정 이메일을 발송했습니다.", "success");
  } catch (error) {
    setMessage(friendlyError(error, "비밀번호 재설정"), "error");
  }
}

async function handleOAuth(provider) {
  if (provider === "naver") {
    setMessage("네이버 로그인은 앱과 동일하게 준비 중입니다.", "error");
    return;
  }

  try {
    const client = await ensureSupabase();
    const { error } = await client.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: window.location.origin,
      },
    });

    if (error) {
      setMessage(friendlyError(error, "소셜 로그인"), "error");
    }
  } catch (error) {
    setMessage(friendlyError(error, "소셜 로그인"), "error");
  }
}

function goTo(route, push = true) {
  const nextRoute = routes.includes(route) ? route : "/";

  if (protectedRoutes.includes(nextRoute) && !state.session) {
    state.requestedRoute = nextRoute;
    renderRoute("/");
    if (push) history.pushState({}, "", "/");
    showToast("로그인 후 이용할 수 있습니다.");
    return;
  }

  renderRoute(nextRoute);
  if (push && window.location.pathname !== nextRoute) {
    history.pushState({}, "", nextRoute);
  }
}

function renderRoute(route) {
  const isLanding = route === "/";

  els.landingView.hidden = !isLanding;
  els.dashboardView.hidden = isLanding;
  els.publicNav.hidden = !isLanding;
  els.appNav.hidden = isLanding;

  document.querySelectorAll("[data-route]").forEach((button) => {
    button.classList.toggle("active", button.dataset.route === route);
  });

  document.querySelectorAll(".app-page").forEach((page) => {
    page.hidden = page.dataset.page !== route;
  });

  if (!isLanding) {
    renderApp();
    setTimeout(() => {
      discoverMap?.invalidateSize();
      createMap?.invalidateSize();
    }, 0);
  }
}

function renderApp() {
  renderCounts();
  renderHomeClues();
  renderJoinClues();
  renderAdmin();
  renderMaps();
}

function renderCounts() {
  els.approvedCount.textContent = state.clues.filter(isVisibleClue).length;
  els.pendingCount.textContent = state.clues.filter(isPendingClue).length;
  els.joinedCount.textContent = state.clues.filter((clue) => clue.joinedByMe).length;
}

function statusLabel(status) {
  if (status === "active" || status === "approved") return "공개됨";
  if (status === "pending_approval" || status === "draft") return "승인 대기";
  return "반려됨";
}

function clueCard(clue, actions = "") {
  const locationMeta = hasLocation(clue)
    ? `<div class="location-meta">지도 위치 ${formatCoordinate(clue.latitude)}, ${formatCoordinate(clue.longitude)} · 반경 ${clue.radiusMeters}m</div>`
    : "";

  return `
    <article class="clue-card">
      <header>
        <div>
          <h3>${escapeHtml(clue.title)}</h3>
        </div>
        <span class="status ${clue.status}">${statusLabel(clue.status)}</span>
      </header>
      <p>${escapeHtml(clue.description)}</p>
      <div class="tag-row">
        <span class="tag">${escapeHtml(categoryLabels[clue.category] || clue.category)}</span>
        <span class="tag">${escapeHtml(clue.place)}</span>
        <span class="tag">${clue.joined}/${clue.capacity}명</span>
      </div>
      ${locationMeta}
      ${actions ? `<div class="card-actions">${actions}</div>` : ""}
    </article>
  `;
}

function hasLocation(clue) {
  return Number.isFinite(clue.latitude) && Number.isFinite(clue.longitude);
}

function formatCoordinate(value) {
  return Number(value).toFixed(4);
}

function renderMaps() {
  if (!els.discoverMap || !els.createMap) return;

  ensureLeaflet()
    .then(() => {
      setupMaps();
      renderDiscoverMap();
      renderCreateMap();
    })
    .catch(() => {
      els.discoverMap.innerHTML = `<div class="permission-card"><strong>지도를 불러오지 못했습니다.</strong><span>네트워크 연결 후 다시 시도해주세요.</span></div>`;
      els.createMap.innerHTML = `<div class="permission-card"><strong>지도를 불러오지 못했습니다.</strong><span>장소명만으로도 클루 등록은 가능합니다.</span></div>`;
    });
}

function setupMaps() {
  if (mapsInitialized || !window.L) return;

  const tileLayer = () =>
    window.L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
      attribution: "&copy; OpenStreetMap &copy; CARTO",
      subdomains: "abcd",
      maxZoom: 20,
    });

  discoverMap = window.L.map(els.discoverMap, {
    zoomControl: true,
    attributionControl: true,
  }).setView([defaultLocation.lat, defaultLocation.lng], 12);
  tileLayer().addTo(discoverMap);
  discoverLayer = window.L.layerGroup().addTo(discoverMap);

  createMap = window.L.map(els.createMap, {
    zoomControl: true,
    attributionControl: true,
  }).setView([createLocation.lat, createLocation.lng], 15);
  tileLayer().addTo(createMap);
  createMap.on("click", (event) => {
    setCreateLocation(event.latlng.lat, event.latlng.lng);
  });

  mapsInitialized = true;
}

function renderDiscoverMap() {
  if (!discoverMap || !discoverLayer) return;

  discoverLayer.clearLayers();
  const mappedClues = state.clues.filter(isVisibleClue).filter(hasLocation);

  if (mappedClues.length === 0) {
    discoverMap.setView([defaultLocation.lat, defaultLocation.lng], 12);
    setTimeout(() => discoverMap.invalidateSize(), 0);
    return;
  }

  const bounds = [];
  mappedClues.forEach((clue) => {
    const marker = window.L.marker([clue.latitude, clue.longitude]).bindPopup(`
      <div class="clue-map-popup">
        <strong>${escapeHtml(clue.title)}</strong>
        <span>${escapeHtml(clue.place)}</span>
        <span>${clue.joined}/${clue.capacity}명 · ${escapeHtml(categoryLabels[clue.category] || clue.category)}</span>
      </div>
    `);
    marker.addTo(discoverLayer);

    if (clue.radiusMeters) {
      window.L.circle([clue.latitude, clue.longitude], {
        radius: clue.radiusMeters,
        color: "#facc15",
        weight: 1,
        fillColor: "#facc15",
        fillOpacity: 0.12,
      }).addTo(discoverLayer);
    }
    bounds.push([clue.latitude, clue.longitude]);
  });

  if (bounds.length === 1) {
    discoverMap.setView(bounds[0], 15);
  } else {
    discoverMap.fitBounds(bounds, { padding: [30, 30] });
  }
  setTimeout(() => discoverMap.invalidateSize(), 0);
}

function renderCreateMap() {
  if (!createMap) return;
  setCreateLocation(createLocation.lat, createLocation.lng, false);
  setTimeout(() => createMap.invalidateSize(), 0);
}

function setCreateLocation(lat, lng, moveMap = true) {
  createLocation.lat = Number(lat);
  createLocation.lng = Number(lng);

  if (els.selectedLocationText) {
    els.selectedLocationText.textContent = `선택 위치 ${formatCoordinate(createLocation.lat)}, ${formatCoordinate(createLocation.lng)}`;
  }

  if (!createMap || !window.L) return;

  const radiusMeters = Number(document.querySelector("#clueRadius")?.value || 50);
  const point = [createLocation.lat, createLocation.lng];
  if (!createMarker) {
    createMarker = window.L.marker(point, { draggable: true }).addTo(createMap);
    createMarker.on("dragend", () => {
      const next = createMarker.getLatLng();
      setCreateLocation(next.lat, next.lng, false);
    });
  } else {
    createMarker.setLatLng(point);
  }

  if (!createRadiusCircle) {
    createRadiusCircle = window.L.circle(point, {
      radius: radiusMeters,
      color: "#22c55e",
      weight: 1,
      fillColor: "#22c55e",
      fillOpacity: 0.12,
    }).addTo(createMap);
  } else {
    createRadiusCircle.setLatLng(point);
    createRadiusCircle.setRadius(radiusMeters);
  }

  if (moveMap) {
    createMap.setView(point, Math.max(createMap.getZoom(), 15));
  }
}

function useBrowserLocation(target = "create") {
  if (!navigator.geolocation) {
    showToast("이 브라우저에서는 현재 위치를 사용할 수 없습니다.");
    return;
  }

  navigator.geolocation.getCurrentPosition(
    (position) => {
      const lat = position.coords.latitude;
      const lng = position.coords.longitude;
      if (target === "discover" && discoverMap) {
        discoverMap.setView([lat, lng], 15);
        showToast("현재 위치 기준으로 지도를 이동했습니다.");
        return;
      }

      setCreateLocation(lat, lng);
      showToast("현재 위치를 클루 위치로 선택했습니다.");
    },
    () => {
      showToast("현재 위치 권한을 확인해주세요.");
    },
    { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 },
  );
}

function renderHomeClues() {
  if (state.isLoadingClues) {
    els.homeClues.innerHTML = `<div class="permission-card"><strong>클루를 불러오는 중입니다.</strong></div>`;
    return;
  }

  const approved = state.clues.filter(isVisibleClue);
  if (approved.length === 0) {
    els.homeClues.innerHTML = `
      <div class="permission-card">
        <strong>공개된 클루가 없습니다.</strong>
        <span>앱 또는 웹에서 승인된 클루가 생기면 이곳에 표시됩니다.</span>
      </div>
    `;
    return;
  }

  els.homeClues.innerHTML = approved.map((clue) => {
    const action = `<button class="join" type="button" data-route="/join">참여 화면으로</button>`;
    return clueCard(clue, action);
  }).join("");
}

function renderJoinClues() {
  const approved = state.clues.filter(isVisibleClue);
  if (approved.length === 0) {
    els.joinClues.innerHTML = `
      <div class="permission-card">
        <strong>참여 가능한 클루가 없습니다.</strong>
        <span>공개 상태의 클루만 참여 목록에 표시됩니다.</span>
      </div>
    `;
    return;
  }

  els.joinClues.innerHTML = approved.map((clue) => {
    const isFull = clue.joined >= clue.capacity;
    const disabledText = clue.joinedByMe ? "참여 완료" : isFull ? "정원 마감" : "참여하기";
    const action = `<button class="${clue.joinedByMe || isFull ? "ghost" : "join"}" type="button" data-join="${clue.id}" ${clue.joinedByMe || isFull ? "disabled" : ""}>${disabledText}</button>`;
    return clueCard(clue, action);
  }).join("");
}

function renderAdmin() {
  els.adminDenied.hidden = state.isAdmin;
  els.adminBoard.hidden = !state.isAdmin;

  if (!state.isAdmin) return;

  const pending = state.clues.filter(isPendingClue);
  if (pending.length === 0) {
    els.adminClues.innerHTML = `
      <div class="permission-card">
        <strong>승인 대기 클루가 없습니다.</strong>
        <span>사용자가 새 클루를 만들면 이곳에 표시됩니다.</span>
      </div>
    `;
    return;
  }

  els.adminClues.innerHTML = pending.map((clue) => {
    const actions = `
      <button class="approve" type="button" data-approve="${clue.id}">승인</button>
      <button class="reject" type="button" data-reject="${clue.id}">반려</button>
    `;
    return clueCard(clue, actions);
  }).join("");
}

function createClue(event) {
  event.preventDefault();
  createClueInDb(event.currentTarget).catch((error) => {
    showToast(friendlyError(error, "클루 등록"));
  });
}

async function createClueInDb(form) {
  if (!state.userId) {
    showToast("로그인 후 클루를 만들 수 있습니다.");
    return;
  }

  const client = await ensureSupabase();
  const payload = {
    creator_id: state.userId,
    title: document.querySelector("#clueTitle").value.trim(),
    address: document.querySelector("#cluePlace").value.trim(),
    center_address: document.querySelector("#cluePlace").value.trim(),
    center_latitude: createLocation.lat,
    center_longitude: createLocation.lng,
    radius_meters: Number(document.querySelector("#clueRadius").value || 50),
    category: document.querySelector("#clueCategory").value,
    max_participants: Number(document.querySelector("#clueCapacity").value || 1),
    current_participants: 0,
    status: "pending_approval",
    description: document.querySelector("#clueDescription").value.trim(),
  };

  let { error } = await client.from("clues").insert(payload);
  if (error && /center_|radius_meters|schema cache|column/i.test(error.message || "")) {
    const fallbackPayload = { ...payload };
    delete fallbackPayload.center_address;
    delete fallbackPayload.center_latitude;
    delete fallbackPayload.center_longitude;
    delete fallbackPayload.radius_meters;
    const fallbackResult = await client.from("clues").insert(fallbackPayload);
    error = fallbackResult.error;
  }
  if (error) throw error;

  form.reset();
  document.querySelector("#clueCapacity").value = 8;
  document.querySelector("#clueRadius").value = 50;
  setCreateLocation(defaultLocation.lat, defaultLocation.lng);
  await loadClues();
  renderApp();
  showToast("클루가 승인 대기 상태로 등록되었습니다.");
  goTo("/admin", true);
}

function joinClue(id) {
  joinClueInDb(id).catch((error) => {
    showToast(friendlyError(error, "클루 참여"));
  });
}

async function joinClueInDb(id) {
  const clue = state.clues.find((item) => item.id === id);
  if (!clue || !isVisibleClue(clue)) return;
  if (clue.joinedByMe || clue.joined >= clue.capacity) return;
  if (!state.userId) return;

  const client = await ensureSupabase();
  const { error } = await client.from("participations").insert({
    clue_id: id,
    user_id: state.userId,
    status: "joined",
    started_at: new Date().toISOString(),
  });

  if (error) throw error;

  await loadClues();
  renderApp();
  showToast("클루 참여가 완료되었습니다.");
}

function updateClueStatus(id, status) {
  updateClueStatusInDb(id, status).catch((error) => {
    showToast(friendlyError(error, "상태 변경"));
  });
}

async function updateClueStatusInDb(id, status) {
  if (!state.isAdmin) {
    showToast("관리자 권한이 필요합니다.");
    return;
  }

  const nextStatus = status === "approved" ? "active" : "rejected";
  const client = await ensureSupabase();
  const { error } = await client.from("clues").update({ status: nextStatus }).eq("id", id);
  if (error) throw error;

  await loadClues();
  renderApp();
  showToast(status === "approved" ? "클루를 승인했습니다." : "클루를 반려했습니다.");
}

function saveProfile(event) {
  event.preventDefault();
  saveProfileInDb().catch((error) => {
    showToast(friendlyError(error, "회원정보 저장"));
  });
}

async function saveProfileInDb() {
  if (!state.userId) return;

  const nickname = document.querySelector("#profileNickname").value.trim() || "런클루 크루";
  const bio = document.querySelector("#profileBio").value.trim();
  const client = await ensureSupabase();
  const { error } = await client
    .from("profiles")
    .update({ nickname, bio })
    .eq("id", state.userId);

  if (error) throw error;

  await loadProfile();
  updateUserChrome();
  showToast("회원정보가 저장되었습니다.");
}

async function logout() {
  if (supabaseClient) {
    await supabaseClient.auth.signOut();
  }
  state.session = null;
  state.userId = null;
  state.profile = null;
  state.isAdmin = false;
  state.clues = [];
  state.participations = [];
  els.adminToggle.checked = false;
  goTo("/", true);
  showToast("로그아웃되었습니다.");
}

function showToast(text) {
  window.clearTimeout(toastTimer);
  els.toast.textContent = text;
  els.toast.classList.add("show");
  toastTimer = window.setTimeout(() => {
    els.toast.classList.remove("show");
  }, 2200);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

document.addEventListener("click", (event) => {
  const routeButton = event.target.closest("[data-route]");
  if (routeButton) {
    goTo(routeButton.dataset.route, true);
    return;
  }

  const scrollButton = event.target.closest("[data-scroll]");
  if (scrollButton) {
    document.querySelector(`#${scrollButton.dataset.scroll}`)?.scrollIntoView({ behavior: "smooth" });
    return;
  }

  const demoButton = event.target.closest("[data-demo-login]");
  if (demoButton) {
    applyDemoSession();
    return;
  }

  const locateButton = event.target.closest("[data-map-locate]");
  if (locateButton) {
    useBrowserLocation("discover");
    return;
  }

  const currentLocationButton = event.target.closest("[data-use-current-location]");
  if (currentLocationButton) {
    useBrowserLocation("create");
    return;
  }

  const joinButton = event.target.closest("[data-join]");
  if (joinButton) {
    joinClue(joinButton.dataset.join);
    return;
  }

  const approveButton = event.target.closest("[data-approve]");
  if (approveButton) {
    updateClueStatus(approveButton.dataset.approve, "approved");
    return;
  }

  const rejectButton = event.target.closest("[data-reject]");
  if (rejectButton) {
    updateClueStatus(rejectButton.dataset.reject, "rejected");
  }
});

els.tabs.forEach((tab) => {
  tab.addEventListener("click", () => setMode(tab.dataset.mode));
});

els.modeSwitchButton.addEventListener("click", () => {
  setMode(state.mode === "signup" ? "signin" : "signup");
});

els.togglePasswordButton.addEventListener("click", () => {
  const isPassword = els.passwordInput.type === "password";
  els.passwordInput.type = isPassword ? "text" : "password";
  els.togglePasswordButton.textContent = isPassword ? "숨김" : "보기";
});

document.querySelectorAll("[data-provider]").forEach((button) => {
  button.addEventListener("click", () => handleOAuth(button.dataset.provider));
});

els.adminToggle.addEventListener("change", (event) => {
  event.target.checked = state.isAdmin;
  renderAdmin();
  showToast(state.isAdmin ? "관리자 권한이 확인되었습니다." : "관리자 권한은 DB role로만 설정됩니다.");
});

els.form.addEventListener("submit", handleSubmit);
els.resetPasswordButton.addEventListener("click", handlePasswordReset);
els.createForm.addEventListener("submit", createClue);
els.profileForm.addEventListener("submit", saveProfile);
els.logoutButton.addEventListener("click", logout);
document.querySelector("#clueRadius")?.addEventListener("input", () => {
  setCreateLocation(createLocation.lat, createLocation.lng, false);
});

window.addEventListener("popstate", () => {
  goTo(window.location.pathname, false);
});

setMode("signin");
goTo(initialRoute(), false);
initSupabase();
