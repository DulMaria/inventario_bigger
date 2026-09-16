# 🏗️ inventario_bigger — Sistema de Gestión de Inventario, Solicitudes y Cotizaciones para Obras

**inventario_bigger** es una solución tecnológica multiplataforma (Móvil y Web) desarrollada en **Flutter** con backend en **Supabase** (PostgreSQL), diseñada para digitalizar, optimizar y controlar de forma integral el flujo de insumos y materiales en proyectos de construcción.

El sistema conecta en tiempo real a todos los actores clave de una obra, garantizando la trazabilidad desde el requerimiento inicial hasta la entrega final en campo.

---

### 🔄 Flujo de Vida de una Solicitud:
1. **👷 Obrero / Técnico**: Crea la solicitud de materiales especificando la obra, piso, cantidades y fotos de referencia.
2. **👔 Gerente de Obra**: Revisa y autoriza o rechaza las solicitudes de material.
3. **🛒 Encargado de Compras**: Recibe las solicitudes autorizadas, adjunta proformas/fotografías de cotizaciones y confirma la compra.
4. **📦 Almacén**: Recibe automáticamente los materiales comprados, gestiona el inventario por entregar y despacha los materiales al obrero solicitante.
5. **🌐 Administrador**: Controla de forma global las obras, pisos, asignación de personal con roles por obra, aprobación de accesos y métricas del dashboard en entorno Web y Móvil.

---

### 🚀 Características Principales:
- **Gestión Multi-Obra y Roles Granulares**: Asignación de usuarios por obra (Gerente, Compras, Almacén, Obrero) con control de estado (Habilitado/Inhabilitado).
- **Control de Proformas y Cotizaciones**: Subida de imágenes de proformas y registro automático en historial para auditoría.
- **Trazabilidad en Almacén**: Separación clara entre materiales *En Almacén* (comprados listos para entregar) e *Historial de Entregas*.
- **Multiplataforma (Web y Móvil)**: Interfaz adaptativa orientada tanto al trabajo en escritorio/panel web como al uso en dispositivos móviles en obra.
- **Backend Escalable**: Autenticación, almacenamiento de imágenes y base de datos relacional con **Supabase**.
