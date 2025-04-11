// === State ===
let gl, canvas, program;
let positionAttrib, texCoordAttrib, matrixUniform, textureUniform, useTextureUniform, colorUniform;
let boardBuffer, playerBuffer, playerIndexBuffer;
let projectionMatrix, viewMatrix, modelMatrix, mvMatrix, mvpMatrix;
let playerIndices;
let texture;
let players = [];
let angleY = 0;
let game;
let eyeX, eyeZ;
let cameraRadius = 1.5;
let zoomSpeed = 0.05;
let rotateSpeed = 0.05;

// === Load glMatrix for 3D transformations ===
function loadScript(url, callback) {
    let script = document.createElement("script");
    script.src = url;
    script.onload = callback;
    document.head.appendChild(script);
}

function setupScene() {
    const vertexShaderSource = `
            attribute vec3 a_position;
            attribute vec2 a_texCoord;
            uniform mat4 u_matrix;
            varying vec2 v_texCoord;
            void main() {
                gl_Position = u_matrix * vec4(a_position, 1.0);
                v_texCoord = a_texCoord;  // Passing texture coordinates directly
            }
        `;

    const fragmentShaderSource = `
            precision mediump float;
            uniform sampler2D u_texture;
            uniform vec3 u_color;
            uniform bool u_useTexture;
            varying vec2 v_texCoord;

            void main() {
                if (u_useTexture) {
                    vec2 rotatedTexCoord = vec2(1.0 - v_texCoord.x, 1.0 - v_texCoord.y);  // Swap and scale the coordinates
                    gl_FragColor = texture2D(u_texture, rotatedTexCoord);
                } else {
                    gl_FragColor = vec4(u_color, 1.0);
                }
            }
        `;

    function createShader(gl, type, source) {
        const shader = gl.createShader(type);
        gl.shaderSource(shader, source);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.log("Shader compile failed:", gl.getShaderInfoLog(shader));
            return null;
        }
        return shader;
    }


    function createProgram(gl, vShader, fShader) {
        program = gl.createProgram();
        gl.attachShader(program, vShader);
        gl.attachShader(program, fShader);
        gl.linkProgram(program);
        if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
            console.log("Program link failed:", gl.getProgramInfoLog(program));
            return null;
        }
        return program;
    }

    vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
    fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource);
    program = createProgram(gl, vertexShader, fragmentShader);
    gl.useProgram(program);

    useTextureUniform = gl.getUniformLocation(program, "u_useTexture");
    colorUniform = gl.getUniformLocation(program, "u_color");


    // === Board as a 3D Plane with texture coordinates ===
    const BOARD_SIZE = 0.95;

    const boardVertices = new Float32Array([
        -BOARD_SIZE, 0.0, -BOARD_SIZE, 0.0, 0.0,
        BOARD_SIZE, 0.0, -BOARD_SIZE, 1.0, 0.0,
        -BOARD_SIZE, 0.0, BOARD_SIZE, 0.0, 1.0,
        BOARD_SIZE, 0.0, BOARD_SIZE, 1.0, 1.0
    ]);


    const playerVertices = new Float32Array([
        // Front face
        -0.05, 0.0, 0.05, // 0
        0.05, 0.0, 0.05, // 1
        0.05, 0.1, 0.05, // 2
        -0.05, 0.1, 0.05, // 3

        // Back face
        -0.05, 0.0, -0.05, // 4
        0.05, 0.0, -0.05, // 5
        0.05, 0.1, -0.05, // 6
        -0.05, 0.1, -0.05  // 7
    ]);

    playerIndices = new Uint16Array([
        // Front
        0, 1, 2, 0, 2, 3,
        // Back
        4, 5, 6, 4, 6, 7,
        // Left
        4, 0, 3, 4, 3, 7,
        // Right
        1, 5, 6, 1, 6, 2,
        // Top
        3, 2, 6, 3, 6, 7,
        // Bottom
        4, 5, 1, 4, 1, 0
    ]);


    function createBuffer(data) {
        let buffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
        gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
        return buffer;
    }


    boardBuffer = createBuffer(boardVertices);
    playerBuffer = createBuffer(playerVertices);

    playerIndexBuffer = gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, playerIndexBuffer);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, playerIndices, gl.STATIC_DRAW);


    positionAttrib = gl.getAttribLocation(program, "a_position");
    gl.enableVertexAttribArray(positionAttrib);
    gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);

    texCoordAttrib = gl.getAttribLocation(program, "a_texCoord");
    gl.enableVertexAttribArray(texCoordAttrib);
    gl.vertexAttribPointer(texCoordAttrib, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);

    matrixUniform = gl.getUniformLocation(program, "u_matrix");
    textureUniform = gl.getUniformLocation(program, "u_texture");

    // === Load the texture ===
    texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);

    const image = new Image();
    image.onload = function () {
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
        gl.generateMipmap(gl.TEXTURE_2D);
        drawScene();
    };
    image.src = '/images/board_image.png';

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    // === Players List ===
    players = [
        { id: 1, position: 1, color: [1, 0, 0] },  // Red
        { id: 2, position: 10, color: [0, 1, 0] }, // Green
        { id: 3, position: 20, color: [0, 0, 1] },
        { id: 4, position: 11, color: [1, 1, 0] },
        { id: 5, position: 12, color: [1, 0, 1] },
        { id: 6, position: 13, color: [0, 1, 1] }  // Blue
    ];
}


export function loadBoard(gameState) {
    game = gameState;
    console.log(game);
    console.log("gamestate loaded");
    // === WebGL Setup ===
    canvas = document.getElementById("webgl-canvas");
    canvas.width = canvas.clientWidth;
    canvas.height = canvas.clientHeight;
    canvas.style.border = "2px solid white";
    
    gl = canvas.getContext("webgl");
    if (!gl) {
        alert("WebGL not supported");
        return;
    }
    gl.enable(gl.BLEND);
    gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    gl.enable(gl.DEPTH_TEST);

    loadScript("https://cdnjs.cloudflare.com/ajax/libs/gl-matrix/2.8.1/gl-matrix-min.js", function () {
        setupScene();
        setupCamera();
        console.log(projectionMatrix);
        setupControls();
        console.log("game: ");
        console.log(game.players)
        
    });
}


function setupCamera() {
    // === Projection & Camera ===
    projectionMatrix = mat4.create();
    viewMatrix = mat4.create();
    modelMatrix = mat4.create();
    mvMatrix = mat4.create();
    mvpMatrix = mat4.create();

    mat4.perspective(projectionMatrix, Math.PI / 3, canvas.width / canvas.height, 0.1, 10);
    mat4.lookAt(viewMatrix, [0, 1.7, cameraRadius], [0, 0, 0], [0, 1, 0]);
}

function updateViewMatrix() {
    eyeX = cameraRadius * Math.sin(angleY);
    eyeZ = cameraRadius * Math.cos(angleY);

    mat4.lookAt(viewMatrix, [eyeX, 1.7, eyeZ], [0, 0, 0], [0, 1, 0]);

    requestAnimationFrame(drawScene); // Smoothly update view
}

function setupControls() {
    let dragging = false;
    let lastX = 0;

    // Mouse controls for rotation
    canvas.addEventListener("mousedown", (e) => {
        dragging = true;
        lastX = e.clientX;
    });
    canvas.addEventListener("mouseup", () => dragging = false);
    canvas.addEventListener("mousemove", (e) => {
        if (!dragging) return;
        let dx = e.clientX - lastX;
        lastX = e.clientX;
        angleY += dx * 0.005;
        updateViewMatrix();
        drawScene();
    });

    // Keyboard controls for rotation (A/D keys)
    document.addEventListener("keydown", (e) => {
        if (e.key === "a" || e.key === "A") {
            angleY -= rotateSpeed;  // Rotate left
            updateViewMatrix();
            drawScene();
        }
        if (e.key === "d" || e.key === "D") {
            angleY += rotateSpeed;  // Rotate right
            updateViewMatrix();
            drawScene();
        }

        // Keyboard controls for zoom (W/S keys)
        if (e.key === "w" || e.key === "W") {
            zoomCamera(zoomSpeed);  // Zoom in
            updateViewMatrix();
            drawScene();
        }
        if (e.key === "s" || e.key === "S") {
            zoomCamera(-zoomSpeed);  // Zoom out
            updateViewMatrix();
            drawScene();
        }
    });
}

function zoomCamera(amount) {
    cameraRadius += amount;
    if (cameraRadius < 0.1) cameraRadius = 0.1; 
    if (cameraRadius > 1.5) cameraRadius = 1.5;

    eyeX = cameraRadius * Math.sin(angleY);
    eyeZ = cameraRadius * Math.cos(angleY);

    mat4.lookAt(viewMatrix, [eyeX, 84.0, eyeZ], [0, 0, 0], [0, 1, 0]);
}


// === Monopoly Board Logic ===
function getBoardPosition(pos, height) {
    let step = 1.6 / 10;
    let half = 0.8;
    // let height = height;
    console.log(height);

    if (pos >= 0 && pos <= 9) return [-half + (pos) * step, height, -half];
    if (pos >= 10 && pos <= 19) return [half, height, -half + (pos - 10) * step];
    if (pos >= 20 && pos <= 29) return [half - (pos - 20) * step, height, half];
    if (pos >= 30 && pos <= 39) return [-half, height, half - (pos - 30) * step];
    return [0, height, 0];
}

export function updateGameState(gameState) {
    game = gameState;
    drawScene();
}

function drawScene() {
    console.log("Drawing")
    console.log(game);
    console.log(game.players);
    console.log("drawing game")
    resizeCanvasToDisplaySize(canvas);
    gl.clearColor(0, 0, 0, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    // gl.useProgram(program);
    gl.enable(gl.DEPTH_TEST);

    // === Draw Board ===
    mat4.identity(modelMatrix);
    mat4.translate(modelMatrix, modelMatrix, [0, -0.01, 0]);
    mat4.multiply(mvMatrix, viewMatrix, modelMatrix);
    mat4.multiply(mvpMatrix, projectionMatrix, mvMatrix);
    gl.uniformMatrix4fv(matrixUniform, false, mvpMatrix);

    gl.bindBuffer(gl.ARRAY_BUFFER, boardBuffer);
    gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);
    gl.enableVertexAttribArray(positionAttrib);

    gl.vertexAttribPointer(texCoordAttrib, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
    gl.enableVertexAttribArray(texCoordAttrib);

    gl.uniform1i(useTextureUniform, 1); // Use texture
    gl.bindBuffer(gl.ARRAY_BUFFER, boardBuffer);
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    let pos
    let positions = [];
    let height = 0.0;
    // === Draw Players ===
    game.players.forEach(player => {
        height = 0.0;
        // const actualPos = game.players[player.id - 1].position;
        const actualPos = player.position;
        console.log("positionss" + positions)
        for (i = 0; i < positions.length; i++) {
            if (positions[i] == actualPos) {
                height += 0.1;
            }
        }
        if (positions.includes(actualPos)) {
            pos = getBoardPosition(actualPos, height);
        }
        else {
            pos = getBoardPosition(actualPos, 0.0);
        }
        positions.push(actualPos);
        mat4.identity(modelMatrix);
        mat4.translate(modelMatrix, modelMatrix, pos);
        mat4.multiply(mvMatrix, viewMatrix, modelMatrix);
        mat4.multiply(mvpMatrix, projectionMatrix, mvMatrix);
        gl.uniformMatrix4fv(matrixUniform, false, mvpMatrix);

        gl.bindBuffer(gl.ARRAY_BUFFER, playerBuffer);
        gl.vertexAttribPointer(positionAttrib, 3, gl.FLOAT, false, 3 * Float32Array.BYTES_PER_ELEMENT, 0);
        gl.enableVertexAttribArray(positionAttrib);
        // Disable texCoordAttrib when using playerBuffer (no texture data)
        gl.disableVertexAttribArray(texCoordAttrib);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, playerIndexBuffer);

        gl.uniform1i(useTextureUniform, 0); // Use solid color
        gl.uniform3fv(colorUniform, players[player.sprite_id].color); // Player color
        // gl.uniform3fv(colorUniform, players.color); // Player color

        gl.drawElements(gl.TRIANGLES, playerIndices.length, gl.UNSIGNED_SHORT, 0);
    });

} 

function resizeCanvasToDisplaySize(canvas) {
    const realToCSSPixels = window.devicePixelRatio || 1;

    // Lookup the size the browser is displaying the canvas in CSS pixels
    const displayWidth = Math.floor(canvas.clientWidth * realToCSSPixels);
    const displayHeight = Math.floor(canvas.clientHeight * realToCSSPixels);

    if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
        canvas.width = displayWidth;
        canvas.height = displayHeight;
        gl.viewport(0, 0, canvas.width, canvas.height);
        mat4.perspective(projectionMatrix, Math.PI / 3, canvas.width / canvas.height, 0.1, 10);
    }
}