import { Injectable, Logger } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import sharp from 'sharp';

import { GenerateStencilDto, GenerateStencilResponseDto } from '../dto/generate-stencil.dto';

@Injectable()
export class AiStencilService {
  private readonly logger = new Logger(AiStencilService.name);

  /**
   * Generates a tattoo stencil from text prompt and style.
   * Produces a clean, high-contrast black lineart stencil on transparent background.
   */
  async generateStencil(dto: GenerateStencilDto): Promise<GenerateStencilResponseDto> {
    const id = uuidv4();
    const normalizedPrompt = dto.prompt.trim();
    const style = (dto.style || 'FINE_LINE').toUpperCase();
    const placement = dto.placement || 'forearm';

    this.logger.log(`Generating AI stencil for prompt: "${normalizedPrompt}" | Style: ${style} | Placement: ${placement}`);

    // Generate placement advice based on anatomical body part
    const { advice, curvatureFactor, estimatedSize } = this.computeAnatomicalAdvice(placement, style);

    // Generate SVG stencil art matching the user prompt and style
    const svgContent = this.createSvgStencil(normalizedPrompt, style);

    // Convert SVG to high-res PNG with transparent background using sharp
    const pngBuffer = await sharp(Buffer.from(svgContent))
      .resize(1024, 1024, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
      .png()
      .toBuffer();

    const stencilDataUrl = `data:image/png;base64,${pngBuffer.toString('base64')}`;

    return {
      id,
      prompt: normalizedPrompt,
      style,
      title: this.createTitleFromPrompt(normalizedPrompt),
      stencilDataUrl,
      placementAdvice: advice,
      suggestedCurvatureFactor: curvatureFactor,
      estimatedSizeCm: estimatedSize,
      createdAt: new Date().toISOString(),
    };
  }

  private computeAnatomicalAdvice(placement: string, style: string) {
    switch (placement.toLowerCase()) {
      case 'forearm':
      case 'antebrazo':
        return {
          advice: 'La zona del antebrazo presenta curvatura cilíndrica media. Se recomienda alinear el eje vertical del diseño con el tendón central para evitar distorsión al girar la muñeca.',
          curvatureFactor: 0.18,
          estimatedSize: { width: 8.5, height: 16.0 },
        };
      case 'wrist':
      case 'muñeca':
        return {
          advice: 'Zona de flexión constante. Es recomendable mantener el trazo fino (Fine Line) y no superar los 6 cm de ancho para evitar expansión de tinta en los pliegues.',
          curvatureFactor: 0.12,
          estimatedSize: { width: 5.0, height: 6.5 },
        };
      case 'biceps':
      case 'arm':
      case 'brazo':
        return {
          advice: 'Excelente superficie anatómica. Permite composiciones envolventes con buena respuesta ante la contracción del músculo.',
          curvatureFactor: 0.22,
          estimatedSize: { width: 11.0, height: 18.0 },
        };
      case 'calf':
      case 'pantorrilla':
      case 'pierna':
        return {
          advice: 'Curvatura vertical pronunciada en la zona del sóleo. Conviene adaptar la base del stencil hacia el tobillo para mantener la proporción.',
          curvatureFactor: 0.25,
          estimatedSize: { width: 12.0, height: 22.0 },
        };
      case 'back':
      case 'espalda':
        return {
          advice: 'Superficie prácticamente plana con baja curvatura. Ideal para composiciones geométricas o piezas complejas de gran escala.',
          curvatureFactor: 0.05,
          estimatedSize: { width: 22.0, height: 32.0 },
        };
      default:
        return {
          advice: `Zona anatómica estándar. Se recomienda previsualizar la alineación dinámica en AR antes de transferir el esténcil.`,
          curvatureFactor: 0.15,
          estimatedSize: { width: 10.0, height: 15.0 },
        };
    }
  }

  private createTitleFromPrompt(prompt: string): string {
    const cleaned = prompt.replace(/[^\w\sáéíóúÁÉÍÓÚñÑ]/gi, '');
    const words = cleaned.split(/\s+/).slice(0, 4).join(' ');
    return words.charAt(0).toUpperCase() + words.slice(1);
  }

  /**
   * Generates a vector stencil based on keywords and selected style.
   * Produces crisp, deep black vector linework with full transparency.
   */
  private createSvgStencil(prompt: string, style: string): string {
    const p = prompt.toLowerCase();
    const strokeWidth = style === 'FINE_LINE' ? '4' : style === 'BLACKWORK' ? '12' : '6';

    let paths = '';

    if (p.includes('dragon') || p.includes('dragón') || p.includes('serpiente') || p.includes('snake')) {
      // Oriental serpent / dragon stencil linework
      paths = `
        <!-- Dragon / Serpent Spine & Body Curves -->
        <path d="M 512 80 C 650 140, 750 280, 680 410 C 610 540, 400 480, 360 600 C 320 720, 520 860, 512 940" 
              fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M 522 95 C 635 155, 725 285, 665 405 C 595 525, 415 470, 380 595 C 345 710, 505 845, 500 925" 
              fill="none" stroke="#000000" stroke-width="${Math.max(2, parseInt(strokeWidth) - 2)}" stroke-linecap="round"/>
        <!-- Scales & Ribs details -->
        ${Array.from({ length: 18 }, (_, i) => {
          const y = 140 + i * 42;
          const offset = Math.sin(i * 0.5) * 60;
          return `<path d="M ${490 + offset} ${y} Q ${530 + offset} ${y + 15} ${512 + offset} ${y + 30}" fill="none" stroke="#000000" stroke-width="3"/>`;
        }).join('')}
        <!-- Dragon Head / Whiskers -->
        <path d="M 512 80 L 480 30 L 512 55 L 544 30 Z" fill="#000000"/>
        <circle cx="495" cy="70" r="4" fill="#000000"/>
        <circle cx="529" cy="70" r="4" fill="#000000"/>
        <path d="M 480 75 Q 430 85 410 130" fill="none" stroke="#000000" stroke-width="4" stroke-linecap="round"/>
        <path d="M 544 75 Q 594 85 614 130" fill="none" stroke="#000000" stroke-width="4" stroke-linecap="round"/>
        <!-- Claws / Accents -->
        <path d="M 670 380 L 740 360 M 670 395 L 750 390 M 665 410 L 735 425" stroke="#000000" stroke-width="5" stroke-linecap="round"/>
        <path d="M 360 620 L 290 600 M 355 635 L 280 630 M 360 650 L 295 665" stroke="#000000" stroke-width="5" stroke-linecap="round"/>
      `;
    } else if (p.includes('lobo') || p.includes('wolf') || p.includes('leon') || p.includes('león') || p.includes('lion')) {
      // Geometric Wolf / Lion Lineart
      paths = `
        <!-- Outer head geometric boundary -->
        <polygon points="512,120 620,240 680,400 640,620 512,820 384,620 344,400 404,240" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linejoin="round"/>
        <!-- Ears -->
        <polygon points="404,240 370,100 450,180" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linejoin="round"/>
        <polygon points="620,240 654,100 574,180" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linejoin="round"/>
        <!-- Eyes & Brow -->
        <polygon points="440,380 480,410 430,420" fill="#000000"/>
        <polygon points="584,380 544,410 594,420" fill="#000000"/>
        <line x1="512" y1="200" x2="512" y2="580" stroke="#000000" stroke-width="${strokeWidth}"/>
        <!-- Muzzle & Snout -->
        <polygon points="512,580 470,680 512,720 554,680" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <polygon points="512,690 495,665 529,665" fill="#000000"/>
        <!-- Sacred Geometry Facets -->
        <line x1="450" y1="180" x2="512" y2="300" stroke="#000000" stroke-width="3"/>
        <line x1="574" y1="180" x2="512" y2="300" stroke="#000000" stroke-width="3"/>
        <line x1="512" y1="300" x2="440" y2="380" stroke="#000000" stroke-width="3"/>
        <line x1="512" y1="300" x2="584" y2="380" stroke="#000000" stroke-width="3"/>
        <line x1="384" y1="620" x2="470" y2="680" stroke="#000000" stroke-width="3"/>
        <line x1="640" y1="620" x2="554" y2="680" stroke="#000000" stroke-width="3"/>
        <circle cx="512" cy="512" r="380" fill="none" stroke="#000000" stroke-width="2" stroke-dasharray="10,12"/>
      `;
    } else if (p.includes('rosa') || p.includes('rose') || p.includes('flor') || p.includes('flower') || p.includes('loto')) {
      // Botanical Rose / Lotus Stencil
      paths = `
        <!-- Rose petals / Lotus sacred curves -->
        <path d="M 512 360 C 470 320, 440 380, 512 450 C 584 380, 554 320, 512 360 Z" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <path d="M 512 280 C 420 220, 370 340, 470 450" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linecap="round"/>
        <path d="M 512 280 C 604 220, 654 340, 554 450" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linecap="round"/>
        <path d="M 390 390 C 330 460, 410 560, 512 590 C 614 560, 694 460, 634 390" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linecap="round"/>
        <!-- Stem & Leaves -->
        <path d="M 512 590 C 510 690, 520 780, 512 920" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linecap="round"/>
        <!-- Left Leaf -->
        <path d="M 512 670 C 440 650, 410 700, 430 740 C 470 730, 495 700, 512 690" fill="none" stroke="#000000" stroke-width="4"/>
        <line x1="512" y1="675" x2="435" y2="735" stroke="#000000" stroke-width="2"/>
        <!-- Right Leaf -->
        <path d="M 512 730 C 584 710, 614 760, 594 800 C 554 790, 529 760, 512 750" fill="none" stroke="#000000" stroke-width="4"/>
        <line x1="512" y1="735" x2="589" y2="795" stroke="#000000" stroke-width="2"/>
        <!-- Thorns & Minimal Dots -->
        <polygon points="510,630 490,635 510,645" fill="#000000"/>
        <polygon points="514,790 534,795 514,805" fill="#000000"/>
      `;
    } else if (p.includes('daga') || p.includes('dagger') || p.includes('espada') || p.includes('sword')) {
      // Neo-traditional / Cybersigilism Dagger
      paths = `
        <!-- Blade -->
        <polygon points="512,140 550,560 512,680 474,560" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linejoin="round"/>
        <line x1="512" y1="140" x2="512" y2="680" stroke="#000000" stroke-width="${Math.max(2, parseInt(strokeWidth) - 2)}"/>
        <!-- Guard / Cross -->
        <path d="M 380 560 C 440 550, 470 570, 512 560 C 554 570, 584 550, 644 560 L 634 590 C 574 580, 544 600, 512 590 C 480 600, 450 580, 390 590 Z" fill="#000000"/>
        <!-- Handle & Pommel -->
        <rect x="496" y="590" width="32" height="120" rx="4" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <line x1="496" y1="620" x2="528" y2="620" stroke="#000000" stroke-width="4"/>
        <line x1="496" y1="650" x2="528" y2="650" stroke="#000000" stroke-width="4"/>
        <line x1="496" y1="680" x2="528" y2="680" stroke="#000000" stroke-width="4"/>
        <circle cx="512" cy="740" r="30" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <circle cx="512" cy="740" r="12" fill="#000000"/>
        <!-- Cybersigilism / Astral halo -->
        <circle cx="512" cy="400" r="180" fill="none" stroke="#000000" stroke-width="2" stroke-dasharray="6,8"/>
        <path d="M 332 400 L 260 400 M 692 400 L 764 400" stroke="#000000" stroke-width="3" stroke-linecap="round"/>
      `;
    } else {
      // Sacred Geometry / Cybersigilism Mandala Master Stencil
      paths = `
        <!-- Sacred Geometry Concentric Rings & Hexagram -->
        <circle cx="512" cy="512" r="360" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <circle cx="512" cy="512" r="280" fill="none" stroke="#000000" stroke-width="3" stroke-dasharray="8,10"/>
        <circle cx="512" cy="512" r="160" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <polygon points="512,152 720,512 512,872 304,512" fill="none" stroke="#000000" stroke-width="${strokeWidth}" stroke-linejoin="round"/>
        <polygon points="512,872 720,512 512,152 304,512" fill="none" stroke="#000000" stroke-width="2" transform="rotate(45 512 512)"/>
        <!-- Central Sun / Eye -->
        <circle cx="512" cy="512" r="60" fill="none" stroke="#000000" stroke-width="${strokeWidth}"/>
        <circle cx="512" cy="512" r="24" fill="#000000"/>
        <!-- Cardinal Rays -->
        <line x1="512" y1="60" x2="512" y2="152" stroke="#000000" stroke-width="5" stroke-linecap="round"/>
        <line x1="512" y1="872" x2="512" y2="964" stroke="#000000" stroke-width="5" stroke-linecap="round"/>
        <line x1="60" y1="512" x2="152" y2="512" stroke="#000000" stroke-width="5" stroke-linecap="round"/>
        <line x1="872" y1="512" x2="964" y2="512" stroke="#000000" stroke-width="5" stroke-linecap="round"/>
        <!-- Moon Crescents -->
        <path d="M 512 232 C 480 280, 544 320, 512 370 C 470 320, 480 270, 512 232 Z" fill="#000000"/>
        <path d="M 512 792 C 480 744, 544 704, 512 654 C 470 704, 480 754, 512 792 Z" fill="#000000"/>
      `;
    }

    return `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
        <!-- Transparent background, clean black stencil vectors -->
        <g stroke-linecap="round" stroke-linejoin="round">
          ${paths}
        </g>
      </svg>
    `;
  }
}
